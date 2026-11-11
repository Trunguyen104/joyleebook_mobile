import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/chapter.dart';
import '../../domain/models/chapter_detail.dart';
import '../../domain/models/downloaded_series.dart';
import '../../domain/models/series.dart';
import '../services/offline_database_service.dart';
import '../services/reading_preferences_service.dart';

/// RIVERPOD PROVIDER: Cung cấp OfflineSeriesRepository
final offlineSeriesRepositoryProvider = Provider<OfflineSeriesRepository>((
  ref,
) {
  final db = ref.watch(offlineDatabaseServiceProvider);
  return OfflineSeriesRepository(db);
});

/// REPOSITORY - Quản lý dữ liệu đọc ngoại tuyến (Offline Series & Chapters) trong SQLite
class OfflineSeriesRepository {
  final OfflineDatabaseService _db;

  OfflineSeriesRepository(this._db);

  /// Lấy danh sách tất cả tác phẩm đã tải về máy (mặc định lấy các bộ đã hoàn tất hoặc đang dở)
  Future<List<DownloadedSeries>> getDownloadedSeriesList({
    bool onlyCompleted = false,
  }) async {
    final rows = await _db.getAllDownloadedSeriesRaw(
      statusFilter: onlyCompleted ? 'completed' : null,
    );
    return rows.map(_mapRowToDownloadedSeries).toList(growable: false);
  }

  /// Lấy thông tin một bộ truyện đã tải theo [seriesId]
  Future<DownloadedSeries?> getDownloadedSeries(String seriesId) async {
    final row = await _db.getDownloadedSeriesRaw(seriesId);
    if (row == null) return null;
    return _mapRowToDownloadedSeries(row);
  }

  /// Lấy danh sách chương đã tải của một bộ truyện
  Future<List<Chapter>> getDownloadedChapters(String seriesId) async {
    final rows = await _db.getDownloadedChaptersRaw(seriesId);
    return rows.map(_mapRowToChapter).toList(growable: false);
  }

  /// Lấy nội dung chi tiết một chương từ SQLite
  Future<ChapterDetail?> getDownloadedChapterDetail(String chapterId) async {
    final row = await _db.getDownloadedChapterDetailRaw(chapterId);
    if (row == null) return null;

    var totalChapters = (row['total_chapters'] as int?) ?? 0;
    if (totalChapters <= 0) {
      final seriesRow = await _db.getDownloadedSeriesRaw(
        row['series_id'] as String,
      );
      totalChapters = (seriesRow?['total_chapters'] as int?) ?? 0;
    }

    final publishedAtStr = row['published_at'] as String?;
    return ChapterDetail(
      id: row['id'] as String,
      seriesId: row['series_id'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      sortOrder: (row['sort_order'] as int?) ?? 1,
      totalChapters: totalChapters,
      status: (row['status'] as int?) ?? 1,
      publishedAt: publishedAtStr != null
          ? DateTime.tryParse(publishedAtStr)
          : null,
      isOffline: true,
    );
  }

  /// Kiểm tra trạng thái tải hoàn tất của một bộ truyện
  Future<bool> isSeriesDownloaded(String seriesId) {
    return _db.isSeriesDownloaded(seriesId);
  }

  /// Kiểm tra một chương đã có sẵn offline hay chưa
  Future<bool> isChapterDownloaded(String chapterId) {
    return _db.isChapterDownloaded(chapterId);
  }

  /// Lấy tập hợp ID các chương đã tải thành công của một bộ truyện
  Future<Set<String>> getDownloadedChapterIds(String seriesId) {
    return _db.getDownloadedChapterIds(seriesId);
  }

  /// Lấy tổng dung lượng đã sử dụng (bytes) của toàn bộ kho offline
  Future<int> getTotalDownloadedBytes() {
    return _db.getTotalDownloadedBytes();
  }

  /// Xóa bản tải của một tác phẩm (bao gồm database records và ảnh bìa trên đĩa)
  Future<void> deleteDownloadedSeries(String seriesId) async {
    final seriesRow = await _db.getDownloadedSeriesRaw(seriesId);
    final coverPath = seriesRow?['cover_local_path'] as String?;

    await _db.deleteSeries(seriesId);

    if (coverPath != null && coverPath.trim().isNotEmpty) {
      await _safeDeleteFile(coverPath);
    }
  }

  /// Xóa toàn bộ tác phẩm đã tải về
  Future<void> deleteAllDownloads() async {
    final rows = await _db.getAllDownloadedSeriesRaw();
    await _db.deleteAllDownloads();

    for (final row in rows) {
      final coverPath = row['cover_local_path'] as String?;
      if (coverPath != null && coverPath.trim().isNotEmpty) {
        await _safeDeleteFile(coverPath);
      }
    }
  }

  /// Lưu tiến độ đọc khi ngoại tuyến vào SQLite
  Future<void> saveOfflineProgress({
    required String seriesId,
    required String chapterId,
    required int sortOrder,
    required double readPercentage,
    bool isSynced = false,
  }) {
    return _db.saveOfflineProgress(
      seriesId: seriesId,
      chapterId: chapterId,
      sortOrder: sortOrder,
      readPercentage: readPercentage,
      isSynced: isSynced,
    );
  }

  /// Lấy tiến độ đọc đã lưu trong SQLite theo [seriesId]
  Future<LocalReadingProgress?> getOfflineProgress(String seriesId) async {
    final row = await _db.getOfflineProgressRaw(seriesId);
    if (row == null) return null;
    return _mapRowToProgress(row);
  }

  /// Lấy danh sách các tiến độ đọc chưa được đồng bộ lên Gateway
  Future<List<LocalReadingProgress>> getUnsyncedProgress() async {
    final rows = await _db.getUnsyncedProgressRaw();
    return rows.map(_mapRowToProgress).toList(growable: false);
  }

  /// Đánh dấu một bản ghi tiến độ đã đồng bộ xong
  Future<void> markProgressSynced(String seriesId) {
    return _db.markProgressSynced(seriesId);
  }

  Future<void> _safeDeleteFile(String path) async {
    if (kIsWeb) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Không làm crash app nếu xóa file vật lý thất bại
    }
  }

  DownloadedSeries _mapRowToDownloadedSeries(Map<String, dynamic> row) {
    List<String> genres = const [];
    final genresStr = row['genres_json'] as String?;
    if (genresStr != null && genresStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(genresStr);
        if (decoded is List) {
          genres = decoded.map((e) => e.toString()).toList(growable: false);
        }
      } catch (_) {}
    }

    return DownloadedSeries(
      id: row['id'] as String,
      title: row['title'] as String,
      authorName: row['author_name'] as String,
      description:
          (row['description'] as String?) ??
          'Chưa có tóm tắt cho tác phẩm này.',
      coverLocalPath: row['cover_local_path'] as String?,
      coverImageUrl: (row['cover_image_url'] as String?) ?? '',
      status: SeriesStatus.fromInt((row['status'] as int?) ?? 1),
      genres: genres,
      totalChapters: (row['total_chapters'] as int?) ?? 0,
      downloadedChaptersCount: (row['downloaded_chapters_count'] as int?) ?? 0,
      totalBytes: (row['total_bytes'] as int?) ?? 0,
      downloadedAt:
          DateTime.tryParse(row['downloaded_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
    );
  }

  Chapter _mapRowToChapter(Map<String, dynamic> row) {
    return Chapter(
      id: row['id'] as String,
      seriesId: row['series_id'] as String,
      sortOrder: (row['sort_order'] as int?) ?? 1,
      title: row['title'] as String,
      isFree: ((row['is_free'] as int?) ?? 1) == 1,
      durationMinutes: (row['duration_minutes'] as int?) ?? 15,
    );
  }

  LocalReadingProgress _mapRowToProgress(Map<String, dynamic> row) {
    return LocalReadingProgress(
      seriesId: row['series_id'] as String,
      chapterId: row['chapter_id'] as String,
      sortOrder: (row['sort_order'] as int?) ?? 1,
      readPercentage: (row['read_percentage'] as num?)?.toDouble() ?? 0.0,
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
