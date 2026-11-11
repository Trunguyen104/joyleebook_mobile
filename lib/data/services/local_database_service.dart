import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/chapter_detail.dart';
import '../../domain/models/offline_chapter.dart';
import '../../domain/models/offline_series.dart';

const _databaseVersion = 3;
const _databaseName = 'joyleebook_offline.db';
const _offlineSeriesTable = 'offline_series';
const _offlineTable = 'offline_chapters';

/// SQLite cục bộ cho nội dung chương đã tải.
/// Database được mở một lần và tái sử dụng trong toàn bộ app.
class LocalDatabaseService {
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final path = join(await getDatabasesPath(), _databaseName);
    final opened = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_offlineSeriesTable (
            user_id TEXT NOT NULL,
            series_id TEXT NOT NULL,
            title TEXT NOT NULL DEFAULT '',
            author_name TEXT NOT NULL DEFAULT '',
            cover_image_url TEXT NOT NULL DEFAULT '',
            status INTEGER NOT NULL DEFAULT 1,
            total_chapters INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (user_id, series_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE $_offlineTable (
            user_id TEXT NOT NULL,
            chapter_id TEXT NOT NULL,
            series_id TEXT NOT NULL,
            series_title TEXT NOT NULL DEFAULT '',
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            total_chapters INTEGER NOT NULL,
            status INTEGER NOT NULL,
            published_at TEXT,
            downloaded_at INTEGER NOT NULL,
            server_updated_at TEXT,
            PRIMARY KEY (user_id, chapter_id)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_offline_series '
          'ON $_offlineTable (user_id, series_id)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE $_offlineTable ADD COLUMN series_title TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE $_offlineSeriesTable (
              user_id TEXT NOT NULL,
              series_id TEXT NOT NULL,
              title TEXT NOT NULL DEFAULT '',
              author_name TEXT NOT NULL DEFAULT '',
              cover_image_url TEXT NOT NULL DEFAULT '',
              status INTEGER NOT NULL DEFAULT 1,
              total_chapters INTEGER NOT NULL DEFAULT 0,
              updated_at INTEGER NOT NULL,
              PRIMARY KEY (user_id, series_id)
            )
          ''');
          await db.execute('''
            INSERT INTO $_offlineSeriesTable
              (user_id, series_id, title, updated_at)
            SELECT user_id, series_id, MAX(series_title), MAX(downloaded_at)
            FROM $_offlineTable
            GROUP BY user_id, series_id
          ''');
        }
      },
    );
    _database = opened;
    return opened;
  }

  Future<void> saveChapter({
    required String userId,
    required String seriesId,
    required String seriesTitle,
    String authorName = '',
    String coverImageUrl = '',
    int status = 1,
    int totalChapters = 0,
    required ChapterDetail chapter,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.insert(_offlineSeriesTable, {
        'user_id': userId,
        'series_id': seriesId,
        'title': seriesTitle,
        'author_name': authorName,
        'cover_image_url': coverImageUrl,
        'status': status,
        'total_chapters': totalChapters > 0
            ? totalChapters
            : chapter.totalChapters,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert(_offlineTable, {
        'user_id': userId,
        'chapter_id': chapter.id,
        'series_id': chapter.seriesId,
        'series_title': seriesTitle,
        'title': chapter.title,
        'content': chapter.content,
        'sort_order': chapter.sortOrder,
        'total_chapters': chapter.totalChapters,
        'status': chapter.status,
        'published_at': chapter.publishedAt?.toIso8601String(),
        'downloaded_at': now,
        'server_updated_at': null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<OfflineChapter?> getChapter({
    required String userId,
    required String chapterId,
  }) async {
    final db = await database;
    final rows = await db.query(
      _offlineTable,
      where: 'user_id = ? AND chapter_id = ?',
      whereArgs: [userId, chapterId],
      limit: 1,
    );
    return rows.isEmpty ? null : _mapRow(rows.single);
  }

  Future<Set<String>> getDownloadedChapterIds({
    required String userId,
    required String seriesId,
  }) async {
    final db = await database;
    final rows = await db.query(
      _offlineTable,
      columns: ['chapter_id'],
      where: 'user_id = ? AND series_id = ?',
      whereArgs: [userId, seriesId],
    );
    return rows.map((row) => row['chapter_id'] as String).toSet();
  }

  Future<List<OfflineChapter>> getAllChapters(String userId) async {
    final db = await database;
    final rows = await db.query(
      _offlineTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'series_id ASC, sort_order ASC',
    );
    return rows.map(_mapRow).toList(growable: false);
  }

  Future<List<OfflineSeries>> getOfflineSeries(String userId) async {
    final db = await database;
    final seriesRows = await db.query(
      _offlineSeriesTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    final result = <OfflineSeries>[];
    for (final row in seriesRows) {
      final seriesId = row['series_id']! as String;
      final chapterRows = await db.query(
        _offlineTable,
        where: 'user_id = ? AND series_id = ?',
        whereArgs: [userId, seriesId],
        orderBy: 'sort_order ASC',
      );
      if (chapterRows.isEmpty) continue;
      result.add(
        OfflineSeries(
          userId: userId,
          id: seriesId,
          title: row['title']! as String,
          authorName: row['author_name']! as String,
          coverImageUrl: row['cover_image_url']! as String,
          status: row['status']! as int,
          totalChapters: row['total_chapters']! as int,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            row['updated_at']! as int,
          ),
          chapters: chapterRows.map(_mapRow).toList(growable: false),
        ),
      );
    }
    return result;
  }

  Future<void> deleteChapter({
    required String userId,
    required String chapterId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        _offlineTable,
        columns: ['series_id'],
        where: 'user_id = ? AND chapter_id = ?',
        whereArgs: [userId, chapterId],
        limit: 1,
      );
      await txn.delete(
        _offlineTable,
        where: 'user_id = ? AND chapter_id = ?',
        whereArgs: [userId, chapterId],
      );
      if (rows.isNotEmpty) {
        final seriesId = rows.single['series_id']! as String;
        final remaining = await txn.query(
          _offlineTable,
          columns: ['chapter_id'],
          where: 'user_id = ? AND series_id = ?',
          whereArgs: [userId, seriesId],
          limit: 1,
        );
        if (remaining.isEmpty) {
          await txn.delete(
            _offlineSeriesTable,
            where: 'user_id = ? AND series_id = ?',
            whereArgs: [userId, seriesId],
          );
        }
      }
    });
  }

  Future<void> deleteSeries({
    required String userId,
    required String seriesId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        _offlineTable,
        where: 'user_id = ? AND series_id = ?',
        whereArgs: [userId, seriesId],
      );
      await txn.delete(
        _offlineSeriesTable,
        where: 'user_id = ? AND series_id = ?',
        whereArgs: [userId, seriesId],
      );
    });
  }

  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        _offlineTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        _offlineSeriesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });
  }

  OfflineChapter _mapRow(Map<String, Object?> row) {
    return OfflineChapter(
      userId: row['user_id']! as String,
      id: row['chapter_id']! as String,
      seriesId: row['series_id']! as String,
      seriesTitle: row['series_title'] as String? ?? '',
      title: row['title']! as String,
      content: row['content']! as String,
      sortOrder: row['sort_order']! as int,
      totalChapters: row['total_chapters']! as int,
      status: row['status']! as int,
      publishedAt: _parseDate(row['published_at'] as String?),
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(
        row['downloaded_at']! as int,
      ),
      serverUpdatedAt: _parseDate(row['server_updated_at'] as String?),
    );
  }

  DateTime? _parseDate(String? value) =>
      value == null ? null : DateTime.tryParse(value);
}

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService();
});
