import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../../domain/models/chapter_detail.dart';
import '../../domain/models/series.dart';

/// RIVERPOD PROVIDER: Cung cấp instance dùng chung của OfflineDatabaseService
final offlineDatabaseServiceProvider = Provider<OfflineDatabaseService>((ref) {
  final service = OfflineDatabaseService();
  ref.onDispose(() {
    service.close();
  });
  return service;
});

/// SERVICE: Quản lý cơ sở dữ liệu cục bộ SQLite (sqflite) cho chức năng đọc Offline
class OfflineDatabaseService {
  static const String _dbName = 'joyleebook_offline.db';
  static const int _dbVersion = 1;

  static const String tableSeries = 'offline_series';
  static const String tableChapters = 'offline_chapters';
  static const String tableProgress = 'offline_reading_progress';

  final DatabaseFactory? customDatabaseFactory;
  final String? customPath;

  Database? _db;
  Future<Database>? _openingFuture;

  OfflineDatabaseService({this.customDatabaseFactory, this.customPath});

  /// Mở hoặc trả về instance database hiện tại (thread-safe với _openingFuture)
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _openingFuture ??= _initDatabase();
    _db = await _openingFuture;
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final factory =
        customDatabaseFactory ??
        (kIsWeb ? databaseFactoryFfiWeb : databaseFactory);
    final dbPath =
        customPath ??
        (kIsWeb ? _dbName : p.join(await factory.getDatabasesPath(), _dbName));

    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Dự phòng cho các bản nâng cấp schema trong tương lai
        },
      ),
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $tableSeries (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author_name TEXT NOT NULL,
        description TEXT,
        cover_local_path TEXT,
        cover_image_url TEXT,
        status INTEGER NOT NULL,
        genres_json TEXT,
        total_chapters INTEGER NOT NULL,
        downloaded_chapters_count INTEGER NOT NULL DEFAULT 0,
        total_bytes INTEGER NOT NULL DEFAULT 0,
        download_status TEXT NOT NULL,
        downloaded_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableChapters (
        id TEXT PRIMARY KEY,
        series_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        total_chapters INTEGER NOT NULL DEFAULT 0,
        status INTEGER NOT NULL DEFAULT 1,
        published_at TEXT,
        is_free INTEGER NOT NULL DEFAULT 1,
        duration_minutes INTEGER NOT NULL DEFAULT 15,
        byte_size INTEGER NOT NULL DEFAULT 0,
        downloaded_at TEXT NOT NULL,
        FOREIGN KEY (series_id) REFERENCES $tableSeries (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableProgress (
        series_id TEXT PRIMARY KEY,
        chapter_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        read_percentage REAL NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_offline_chapters_series ON $tableChapters(series_id, sort_order ASC)',
    );
    await db.execute(
      'CREATE INDEX idx_offline_progress_sync ON $tableProgress(is_synced)',
    );
  }

  /// Lưu hoặc cập nhật thông tin một tác phẩm (Series) vào bảng offline_series.
  /// Không dùng ConflictAlgorithm.replace vì SQLite replace sẽ xóa bản ghi cũ và kích hoạt ON DELETE CASCADE xóa mất các chương đã tải.
  Future<void> upsertSeries(
    Series series, {
    String? coverLocalPath,
    int? downloadedChaptersCount,
    int? totalBytes,
    String downloadStatus = 'downloading',
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final existing = await getDownloadedSeriesRaw(series.id);

    if (existing != null) {
      final updateValues = <String, dynamic>{
        'title': series.title,
        'author_name': series.authorName,
        'description': series.description,
        'cover_image_url': series.coverImageUrl,
        'status': series.status == SeriesStatus.completed ? 0 : 1,
        'genres_json': jsonEncode(series.genres),
        'total_chapters': series.totalChapters,
        'download_status': downloadStatus,
        'updated_at': now,
      };
      if (coverLocalPath != null) {
        updateValues['cover_local_path'] = coverLocalPath;
      }
      if (downloadedChaptersCount != null) {
        updateValues['downloaded_chapters_count'] = downloadedChaptersCount;
      }
      if (totalBytes != null) {
        updateValues['total_bytes'] = totalBytes;
      }
      await db.update(
        tableSeries,
        updateValues,
        where: 'id = ?',
        whereArgs: [series.id],
      );
    } else {
      await db.insert(tableSeries, {
        'id': series.id,
        'title': series.title,
        'author_name': series.authorName,
        'description': series.description,
        'cover_local_path': coverLocalPath,
        'cover_image_url': series.coverImageUrl,
        'status': series.status == SeriesStatus.completed ? 0 : 1,
        'genres_json': jsonEncode(series.genres),
        'total_chapters': series.totalChapters,
        'downloaded_chapters_count': downloadedChaptersCount ?? 0,
        'total_bytes': totalBytes ?? 0,
        'download_status': downloadStatus,
        'downloaded_at': now,
        'updated_at': now,
      });
    }
  }

  /// Cập nhật tiến độ tải của một tác phẩm
  Future<void> updateSeriesDownloadStatus(
    String seriesId, {
    required int downloadedChaptersCount,
    required int totalBytes,
    required String downloadStatus,
    int? totalChapters,
    String? coverLocalPath,
  }) async {
    final db = await database;
    final values = <String, dynamic>{
      'downloaded_chapters_count': downloadedChaptersCount,
      'total_bytes': totalBytes,
      'download_status': downloadStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (totalChapters != null) {
      values['total_chapters'] = totalChapters;
    }
    if (coverLocalPath != null) {
      values['cover_local_path'] = coverLocalPath;
    }
    await db.update(
      tableSeries,
      values,
      where: 'id = ?',
      whereArgs: [seriesId],
    );
  }

  /// Lưu một chương vào SQLite
  Future<void> upsertChapter(
    ChapterDetail chapter, {
    bool isFree = true,
    int durationMinutes = 15,
  }) async {
    final db = await database;
    final byteSize = utf8.encode(chapter.content).length;
    await db.insert(tableChapters, {
      'id': chapter.id,
      'series_id': chapter.seriesId,
      'sort_order': chapter.sortOrder,
      'title': chapter.title,
      'content': chapter.content,
      'total_chapters': chapter.totalChapters,
      'status': chapter.status,
      'published_at': chapter.publishedAt?.toIso8601String(),
      'is_free': isFree ? 1 : 0,
      'duration_minutes': durationMinutes,
      'byte_size': byteSize,
      'downloaded_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Lưu hàng loạt chương bằng SQLite Batch Transaction để tối ưu tốc độ
  Future<void> upsertChaptersBatch(
    List<ChapterDetail> chapters, {
    bool isFree = true,
    int durationMinutes = 15,
  }) async {
    if (chapters.isEmpty) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();

    for (final chapter in chapters) {
      final byteSize = utf8.encode(chapter.content).length;
      batch.insert(tableChapters, {
        'id': chapter.id,
        'series_id': chapter.seriesId,
        'sort_order': chapter.sortOrder,
        'title': chapter.title,
        'content': chapter.content,
        'total_chapters': chapter.totalChapters,
        'status': chapter.status,
        'published_at': chapter.publishedAt?.toIso8601String(),
        'is_free': isFree ? 1 : 0,
        'duration_minutes': durationMinutes,
        'byte_size': byteSize,
        'downloaded_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  /// Lấy danh sách tất cả tác phẩm đã tải
  Future<List<Map<String, dynamic>>> getAllDownloadedSeriesRaw({
    String? statusFilter,
  }) async {
    final db = await database;
    if (statusFilter != null) {
      return db.query(
        tableSeries,
        where: 'download_status = ?',
        whereArgs: [statusFilter],
        orderBy: 'updated_at DESC',
      );
    }
    return db.query(tableSeries, orderBy: 'updated_at DESC');
  }

  /// Lấy thông tin chi tiết tác phẩm offline theo [seriesId]
  Future<Map<String, dynamic>?> getDownloadedSeriesRaw(String seriesId) async {
    final db = await database;
    final rows = await db.query(
      tableSeries,
      where: 'id = ?',
      whereArgs: [seriesId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Lấy danh sách chương đã tải của một tác phẩm
  Future<List<Map<String, dynamic>>> getDownloadedChaptersRaw(
    String seriesId,
  ) async {
    final db = await database;
    return db.query(
      tableChapters,
      columns: [
        'id',
        'series_id',
        'sort_order',
        'title',
        'is_free',
        'duration_minutes',
        'byte_size',
        'downloaded_at',
      ],
      where: 'series_id = ?',
      whereArgs: [seriesId],
      orderBy: 'sort_order ASC',
    );
  }

  /// Lấy danh sách ID các chương đã tải thành công (hỗ trợ Resume Download)
  Future<Set<String>> getDownloadedChapterIds(String seriesId) async {
    final db = await database;
    final rows = await db.query(
      tableChapters,
      columns: ['id'],
      where: 'series_id = ?',
      whereArgs: [seriesId],
    );
    return rows.map((r) => r['id'] as String).toSet();
  }

  /// Lấy nội dung chi tiết một chương từ SQLite theo [chapterId]
  Future<Map<String, dynamic>?> getDownloadedChapterDetailRaw(
    String chapterId,
  ) async {
    final db = await database;
    final rows = await db.query(
      tableChapters,
      where: 'id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Tính tổng kích thước (bytes) đã tải của một series
  Future<int> getSeriesBytes(String seriesId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(byte_size), 0) AS total, COUNT(id) AS count FROM $tableChapters WHERE series_id = ?',
      [seriesId],
    );
    if (result.isEmpty) return 0;
    return (result.first['total'] as int?) ?? 0;
  }

  /// Đếm số chương đã tải của một series
  Future<int> getSeriesDownloadedChapterCount(String seriesId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(id) AS count FROM $tableChapters WHERE series_id = ?',
      [seriesId],
    );
    if (result.isEmpty) return 0;
    return (result.first['count'] as int?) ?? 0;
  }

  /// Tính tổng dung lượng (bytes) của toàn bộ kho truyện offline
  Future<int> getTotalDownloadedBytes() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total_bytes), 0) AS total FROM $tableSeries',
    );
    if (result.isEmpty) return 0;
    return (result.first['total'] as int?) ?? 0;
  }

  /// Kiểm tra một tác phẩm đã tải hoàn tất hay chưa
  Future<bool> isSeriesDownloaded(String seriesId) async {
    final db = await database;
    final rows = await db.query(
      tableSeries,
      columns: ['download_status'],
      where: 'id = ? AND download_status = ?',
      whereArgs: [seriesId, 'completed'],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Kiểm tra một chương đã có sẵn trong SQLite hay chưa
  Future<bool> isChapterDownloaded(String chapterId) async {
    final db = await database;
    final rows = await db.query(
      tableChapters,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Xóa một bộ truyện (bảng offline_chapters sẽ tự động xóa theo CASCADE)
  Future<void> deleteSeries(String seriesId) async {
    final db = await database;
    await db.delete(tableSeries, where: 'id = ?', whereArgs: [seriesId]);
  }

  /// Xóa toàn bộ dữ liệu tải về
  Future<void> deleteAllDownloads() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableChapters);
      await txn.delete(tableSeries);
    });
  }

  /// Lưu tiến độ đọc offline (is_synced = 0 để chờ đồng bộ khi có mạng)
  Future<void> saveOfflineProgress({
    required String seriesId,
    required String chapterId,
    required int sortOrder,
    required double readPercentage,
    bool isSynced = false,
  }) async {
    final db = await database;
    await db.insert(tableProgress, {
      'series_id': seriesId,
      'chapter_id': chapterId,
      'sort_order': sortOrder,
      'read_percentage': readPercentage,
      'updated_at': DateTime.now().toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Lấy tiến độ đọc offline theo [seriesId]
  Future<Map<String, dynamic>?> getOfflineProgressRaw(String seriesId) async {
    final db = await database;
    final rows = await db.query(
      tableProgress,
      where: 'series_id = ?',
      whereArgs: [seriesId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Lấy danh sách tiến độ chưa được đồng bộ lên máy chủ
  Future<List<Map<String, dynamic>>> getUnsyncedProgressRaw() async {
    final db = await database;
    return db.query(tableProgress, where: 'is_synced = 0');
  }

  /// Đánh dấu tiến độ đã được đồng bộ thành công
  Future<void> markProgressSynced(String seriesId) async {
    final db = await database;
    await db.update(
      tableProgress,
      {'is_synced': 1},
      where: 'series_id = ?',
      whereArgs: [seriesId],
    );
  }

  /// Đóng kết nối cơ sở dữ liệu
  Future<void> close() async {
    final db = _db;
    _db = null;
    _openingFuture = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
