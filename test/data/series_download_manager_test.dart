import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/data/services/offline_database_service.dart';
import 'package:joyleebook_mobile/data/services/series_download_manager.dart';
import 'package:joyleebook_mobile/domain/models/chapter.dart';
import 'package:joyleebook_mobile/domain/models/chapter_detail.dart';
import 'package:joyleebook_mobile/domain/models/download_task.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _TrackingChapterRepository implements ChapterRepository {
  final List<Chapter> chapters;
  final Map<String, ChapterDetail> details;
  final Set<String> failOnChapterIds;
  final List<String> fetchedChapterIds = [];

  _TrackingChapterRepository({
    required this.chapters,
    required this.details,
    this.failOnChapterIds = const {},
  });

  @override
  Future<List<Chapter>> getChaptersBySeries(String seriesId) async {
    return chapters.where((c) => c.seriesId == seriesId).toList();
  }

  @override
  Future<ChapterDetail> getChapterDetail(String chapterId) async {
    fetchedChapterIds.add(chapterId);
    if (failOnChapterIds.contains(chapterId)) {
      throw const AppException(message: 'Mất kết nối mạng');
    }
    return details[chapterId]!;
  }
}

void main() {
  sqfliteFfiInit();

  late OfflineDatabaseService dbService;
  late Directory tempDir;

  const sampleSeries = Series(
    id: 'series-1',
    title: 'Nhà Giả Kim',
    authorName: 'Paulo Coelho',
    description: 'Cuốn sách về hành trình đi tìm kho báu.',
    coverImageUrl: '',
    status: SeriesStatus.completed,
    totalChapters: 3,
  );

  final sampleChapters = [
    const Chapter(id: 'c1', seriesId: 'series-1', sortOrder: 1, title: 'Ch 1'),
    const Chapter(id: 'c2', seriesId: 'series-1', sortOrder: 2, title: 'Ch 2'),
    const Chapter(id: 'c3', seriesId: 'series-1', sortOrder: 3, title: 'Ch 3'),
  ];

  final sampleDetails = {
    'c1': const ChapterDetail(
      id: 'c1',
      seriesId: 'series-1',
      title: 'Ch 1',
      content: 'Nội dung chương 1',
      sortOrder: 1,
      totalChapters: 3,
      status: 1,
    ),
    'c2': const ChapterDetail(
      id: 'c2',
      seriesId: 'series-1',
      title: 'Ch 2',
      content: 'Nội dung chương 2',
      sortOrder: 2,
      totalChapters: 3,
      status: 1,
    ),
    'c3': const ChapterDetail(
      id: 'c3',
      seriesId: 'series-1',
      title: 'Ch 3',
      content: 'Nội dung chương 3',
      sortOrder: 3,
      totalChapters: 3,
      status: 1,
    ),
  };

  setUp(() async {
    dbService = OfflineDatabaseService(
      customDatabaseFactory: databaseFactoryFfi,
      customPath: inMemoryDatabasePath,
    );
    await dbService.database;
    tempDir = await Directory.systemTemp.createTemp('joyleebook_test_');
  });

  tearDown(() async {
    await dbService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Tải trọn bộ tác phẩm lưu toàn bộ chương và cập nhật completed',
    () async {
      final chapterRepo = _TrackingChapterRepository(
        chapters: sampleChapters,
        details: sampleDetails,
      );
      final manager = SeriesDownloadManager(
        dio: Dio(),
        chapterRepository: chapterRepo,
        offlineDb: dbService,
        customDocumentsDir: () async => tempDir,
      );

      final events = <DownloadTask>[];
      final sub = manager.onTaskUpdated.listen(events.add);

      await manager.startDownload(sampleSeries);

      // Chờ luồng background chạy hoàn tất
      await Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return manager.isDownloading('series-1');
      });

      await sub.cancel();

      expect(chapterRepo.fetchedChapterIds, ['c1', 'c2', 'c3']);
      expect(await dbService.isSeriesDownloaded('series-1'), isTrue);
      expect(await dbService.getSeriesDownloadedChapterCount('series-1'), 3);
      expect(events.last.status, DownloadStatus.completed);
      expect(events.last.downloadedChapters, 3);

      manager.dispose();
    },
  );

  test(
    'Cơ chế Resume: Mất mạng ở chương 2 chỉ tải tiếp phần còn thiếu ở lần sau',
    () async {
      final chapterRepo = _TrackingChapterRepository(
        chapters: sampleChapters,
        details: sampleDetails,
        failOnChapterIds: {'c2'},
      );
      final manager = SeriesDownloadManager(
        dio: Dio(),
        chapterRepository: chapterRepo,
        offlineDb: dbService,
        customDocumentsDir: () async => tempDir,
      );

      // Lần 1: Lỗi ở c2 -> c1 đã lưu vào DB, status thành failed
      await manager.startDownload(sampleSeries);
      await Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return manager.isDownloading('series-1');
      });

      expect(manager.getTask('series-1')?.status, DownloadStatus.failed);
      expect(await dbService.getSeriesDownloadedChapterCount('series-1'), 1);
      expect(chapterRepo.fetchedChapterIds, ['c1', 'c2']);

      // Khôi phục mạng -> Lần 2 bấm Tải tiếp (Resume)
      chapterRepo.failOnChapterIds.clear();
      chapterRepo.fetchedChapterIds.clear();

      await manager.startDownload(sampleSeries);
      await Future.doWhile(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return manager.isDownloading('series-1');
      });

      // Chỉ tải c2 và c3, KHÔNG tải lại c1!
      expect(chapterRepo.fetchedChapterIds, ['c2', 'c3']);
      expect(manager.getTask('series-1')?.status, DownloadStatus.completed);
      expect(await dbService.getSeriesDownloadedChapterCount('series-1'), 3);

      manager.dispose();
    },
  );
}
