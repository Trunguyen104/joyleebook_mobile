import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/models/chapter_detail.dart';
import '../../domain/models/download_task.dart';
import '../../domain/models/series.dart';
import '../repositories/chapter_repository.dart';
import 'api_client.dart';
import 'api_exceptions.dart';
import 'offline_database_service.dart';

/// RIVERPOD PROVIDER: Cung cấp instance SeriesDownloadManager
final seriesDownloadManagerProvider = Provider<SeriesDownloadManager>((ref) {
  final dio = ref.watch(apiClientProvider);
  final chapterRepo = ref.watch(chapterRepositoryProvider);
  final offlineDb = ref.watch(offlineDatabaseServiceProvider);
  final manager = SeriesDownloadManager(
    dio: dio,
    chapterRepository: chapterRepo,
    offlineDb: offlineDb,
  );
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});

/// SERVICE - Quản lý và điều phối tải trọn bộ tác phẩm (Full Series Download)
class SeriesDownloadManager {
  final Dio dio;
  final ChapterRepository chapterRepository;
  final OfflineDatabaseService offlineDb;
  final Future<Directory> Function()? customDocumentsDir;

  final Map<String, DownloadTask> _tasks = {};
  final Set<String> _canceledSeries = {};
  final StreamController<DownloadTask> _taskStreamController =
      StreamController<DownloadTask>.broadcast();

  SeriesDownloadManager({
    required this.dio,
    required this.chapterRepository,
    required this.offlineDb,
    this.customDocumentsDir,
  });

  /// Stream cập nhật tiến độ cho các màn hình UI lắng nghe
  Stream<DownloadTask> get onTaskUpdated => _taskStreamController.stream;

  /// Lấy task hiện tại của một series (nếu có)
  DownloadTask? getTask(String seriesId) => _tasks[seriesId];

  /// Lấy toàn bộ các task đang hoạt động
  Map<String, DownloadTask> get allTasks => Map.unmodifiable(_tasks);

  /// Kiểm tra xem một series có đang được tải ngầm hay không
  bool isDownloading(String seriesId) {
    final task = _tasks[seriesId];
    return task != null && task.status.isActive;
  }

  /// Bắt đầu tải toàn bộ tác phẩm (Full Series Download)
  Future<void> startDownload(Series series) async {
    final seriesId = series.id;

    // Chống spam: Nếu đang tải thì không nhận thêm task
    if (isDownloading(seriesId)) return;

    _canceledSeries.remove(seriesId);

    var task = DownloadTask(
      seriesId: seriesId,
      seriesTitle: series.title,
      totalChapters: series.totalChapters,
      status: DownloadStatus.queued,
      startedAt: DateTime.now(),
    );
    _tasks[seriesId] = task;
    _taskStreamController.add(task);

    // Bắt đầu tải bất đồng bộ trong background
    unawaited(_executeDownload(series));
  }

  /// Hủy hoặc dừng tiến trình tải của một bộ truyện
  void cancelDownload(String seriesId) {
    if (!isDownloading(seriesId)) return;
    _canceledSeries.add(seriesId);

    final task = _tasks[seriesId];
    if (task != null) {
      final updated = task.copyWith(status: DownloadStatus.paused);
      _tasks[seriesId] = updated;
      _taskStreamController.add(updated);
    }
  }

  Future<void> _executeDownload(Series series) async {
    final seriesId = series.id;
    var task =
        _tasks[seriesId] ??
        DownloadTask(
          seriesId: seriesId,
          seriesTitle: series.title,
          totalChapters: series.totalChapters,
        );

    try {
      task = task.copyWith(status: DownloadStatus.downloading);
      _tasks[seriesId] = task;
      _taskStreamController.add(task);

      // Bước 1: Tải và lưu ảnh bìa cục bộ (Cover Image Caching)
      String? localCoverPath;
      if (series.coverImageUrl.isNotEmpty) {
        localCoverPath = await _downloadCoverImage(
          seriesId,
          series.coverImageUrl,
        );
      }

      // Bước 2: Lưu metadata ban đầu vào SQLite
      await offlineDb.upsertSeries(
        series,
        coverLocalPath: localCoverPath,
        downloadStatus: 'downloading',
      );

      // Bước 3: Lấy danh sách toàn bộ chương của bộ truyện
      final allChapters = await chapterRepository.getChaptersBySeries(seriesId);
      if (allChapters.isEmpty) {
        await offlineDb.deleteSeries(seriesId);
        final failedTask = task.copyWith(
          status: DownloadStatus.failed,
          errorMessage: 'Tác phẩm này chưa có chương nào để tải.',
        );
        _tasks[seriesId] = failedTask;
        _taskStreamController.add(failedTask);
        return;
      }

      final totalChapters = allChapters.length;

      // Cập nhật lại total_chapters chính xác vào DB phòng trường hợp SeriesDto trả về 0
      await offlineDb.updateSeriesDownloadStatus(
        seriesId,
        downloadedChaptersCount: await offlineDb
            .getSeriesDownloadedChapterCount(seriesId),
        totalBytes: await offlineDb.getSeriesBytes(seriesId),
        downloadStatus: 'downloading',
        totalChapters: totalChapters,
        coverLocalPath: localCoverPath,
      );

      // Bước 4: Kiểm tra Resume - Lọc ra các chương chưa tải
      final downloadedChapterIds = await offlineDb.getDownloadedChapterIds(
        seriesId,
      );
      var currentBytes = await offlineDb.getSeriesBytes(seriesId);

      task = task.copyWith(
        totalChapters: totalChapters,
        downloadedChapters: downloadedChapterIds.length,
        downloadedBytes: currentBytes,
      );
      _tasks[seriesId] = task;
      _taskStreamController.add(task);

      final pendingChapters = allChapters
          .where((c) => !downloadedChapterIds.contains(c.id))
          .toList(growable: false);

      var downloadedCount = downloadedChapterIds.length;

      // Bước 5: Tải nội dung từng chương và lưu vào SQLite
      for (final chapter in pendingChapters) {
        if (_canceledSeries.contains(seriesId)) {
          // Người dùng đã hủy hoặc tạm dừng
          await offlineDb.updateSeriesDownloadStatus(
            seriesId,
            downloadedChaptersCount: downloadedCount,
            totalBytes: currentBytes,
            downloadStatus: 'paused',
            coverLocalPath: localCoverPath,
          );
          return;
        }

        try {
          final ChapterDetail detail = await chapterRepository.getChapterDetail(
            chapter.id,
          );
          await offlineDb.upsertChapter(
            detail,
            isFree: chapter.isFree,
            durationMinutes: chapter.durationMinutes,
          );

          downloadedCount++;
          currentBytes = await offlineDb.getSeriesBytes(seriesId);

          task = task.copyWith(
            downloadedChapters: downloadedCount,
            downloadedBytes: currentBytes,
          );
          _tasks[seriesId] = task;
          _taskStreamController.add(task);

          // Cập nhật tiến độ vào database sau mỗi chương
          await offlineDb.updateSeriesDownloadStatus(
            seriesId,
            downloadedChaptersCount: downloadedCount,
            totalBytes: currentBytes,
            downloadStatus: 'downloading',
            coverLocalPath: localCoverPath,
          );
        } catch (e) {
          // Nếu 1 chương bị lỗi mạng -> dừng lại và báo failed để người dùng có thể Resume
          final msg = e is AppException ? e.message : 'Lỗi tải chương: $e';
          final failedTask = task.copyWith(
            status: DownloadStatus.failed,
            errorMessage: msg,
          );
          _tasks[seriesId] = failedTask;
          _taskStreamController.add(failedTask);

          await offlineDb.updateSeriesDownloadStatus(
            seriesId,
            downloadedChaptersCount: downloadedCount,
            totalBytes: currentBytes,
            downloadStatus: 'failed',
            coverLocalPath: localCoverPath,
          );
          return;
        }
      }

      // Bước 6: Hoàn tất tải toàn bộ tác phẩm
      await offlineDb.updateSeriesDownloadStatus(
        seriesId,
        downloadedChaptersCount: downloadedCount,
        totalBytes: currentBytes,
        downloadStatus: 'completed',
        coverLocalPath: localCoverPath,
      );

      final completedTask = task.copyWith(
        downloadedChapters: downloadedCount,
        downloadedBytes: currentBytes,
        status: DownloadStatus.completed,
        clearError: true,
      );
      _tasks[seriesId] = completedTask;
      _taskStreamController.add(completedTask);
    } catch (e) {
      final msg = e is AppException ? e.message : 'Lỗi trong quá trình tải: $e';
      final failedTask = (_tasks[seriesId] ?? task).copyWith(
        status: DownloadStatus.failed,
        errorMessage: msg,
      );
      _tasks[seriesId] = failedTask;
      _taskStreamController.add(failedTask);
    }
  }

  Future<String?> _downloadCoverImage(String seriesId, String imageUrl) async {
    if (kIsWeb) return null;
    try {
      final docDir = await (customDocumentsDir != null
          ? customDocumentsDir!()
          : getApplicationDocumentsDirectory());
      final coversDir = Directory(p.join(docDir.path, 'covers'));
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      final ext = p.extension(imageUrl).toLowerCase();
      final validExt = ext.isNotEmpty && ext.length <= 5 ? ext : '.jpg';
      final savePath = p.join(coversDir.path, '$seriesId$validExt');

      final file = File(savePath);
      if (await file.exists()) {
        return savePath;
      }

      await dio.download(
        imageUrl,
        savePath,
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      return savePath;
    } catch (_) {
      // Best-effort: Nếu tải ảnh bìa thất bại, vẫn tiếp tục tải text bình thường
      return null;
    }
  }

  void dispose() {
    _taskStreamController.close();
  }
}
