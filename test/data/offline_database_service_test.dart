import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/data/repositories/offline_series_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/data/services/offline_database_service.dart';
import 'package:joyleebook_mobile/domain/models/chapter_detail.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _NetworkErrorAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: 'No Internet Connection',
    );
  }
}

void main() {
  sqfliteFfiInit();

  late OfflineDatabaseService dbService;
  late OfflineSeriesRepository offlineRepo;

  const sampleSeries = Series(
    id: 'series-1',
    title: 'Đắc Nhân Tâm',
    authorName: 'Dale Carnegie',
    description: 'Nghệ thuật thu phục lòng người.',
    coverImageUrl: 'https://example.com/cover.jpg',
    status: SeriesStatus.completed,
    genres: ['Kỹ năng sống', 'Tâm lý'],
    totalChapters: 2,
  );

  final sampleChapters = [
    const ChapterDetail(
      id: 'chap-1',
      seriesId: 'series-1',
      title: 'Chương 1: Đừng chỉ trích',
      content: 'Nội dung chương 1 dài để tính kích thước byte.',
      sortOrder: 1,
      totalChapters: 2,
      status: 1,
    ),
    const ChapterDetail(
      id: 'chap-2',
      seriesId: 'series-1',
      title: 'Chương 2: Thành thật khen ngợi',
      content: 'Nội dung chương 2 rất hay và ý nghĩa.',
      sortOrder: 2,
      totalChapters: 2,
      status: 1,
    ),
  ];

  setUp(() async {
    dbService = OfflineDatabaseService(
      customDatabaseFactory: databaseFactoryFfi,
      customPath: inMemoryDatabasePath,
    );
    offlineRepo = OfflineSeriesRepository(dbService);
    await dbService.database;
  });

  tearDown(() async {
    await dbService.close();
  });

  test(
    'Lưu và đọc thông tin Series và Chapters theo batch từ SQLite',
    () async {
      await dbService.upsertSeries(
        sampleSeries,
        downloadedChaptersCount: 2,
        totalBytes: 120,
        downloadStatus: 'completed',
      );
      await dbService.upsertChaptersBatch(sampleChapters);

      final downloadedList = await offlineRepo.getDownloadedSeriesList();
      expect(downloadedList.length, 1);
      expect(downloadedList.first.id, 'series-1');
      expect(downloadedList.first.title, 'Đắc Nhân Tâm');
      expect(downloadedList.first.genres, ['Kỹ năng sống', 'Tâm lý']);

      final chapters = await offlineRepo.getDownloadedChapters('series-1');
      expect(chapters.length, 2);
      expect(chapters.first.sortOrder, 1);
      expect(chapters.last.sortOrder, 2);

      final detail = await offlineRepo.getDownloadedChapterDetail('chap-1');
      expect(detail, isNotNull);
      expect(detail!.isOffline, isTrue);
      expect(detail.content, 'Nội dung chương 1 dài để tính kích thước byte.');
    },
  );

  test(
    'Xóa Series tự động xóa toàn bộ Chapters liên quan (ON DELETE CASCADE)',
    () async {
      await dbService.upsertSeries(
        sampleSeries,
        downloadedChaptersCount: 2,
        totalBytes: 120,
        downloadStatus: 'completed',
      );
      await dbService.upsertChaptersBatch(sampleChapters);

      expect(await offlineRepo.isSeriesDownloaded('series-1'), isTrue);
      expect(await offlineRepo.isChapterDownloaded('chap-1'), isTrue);

      await offlineRepo.deleteDownloadedSeries('series-1');

      expect(await offlineRepo.isSeriesDownloaded('series-1'), isFalse);
      expect(await offlineRepo.isChapterDownloaded('chap-1'), isFalse);
      expect(await offlineRepo.getDownloadedChapters('series-1'), isEmpty);
    },
  );

  test('ChapterRepository tự động fallback về SQLite khi mất mạng', () async {
    await dbService.upsertSeries(
      sampleSeries,
      downloadedChaptersCount: 2,
      totalBytes: 120,
      downloadStatus: 'completed',
    );
    await dbService.upsertChaptersBatch(sampleChapters);

    final dio = Dio()..httpClientAdapter = _NetworkErrorAdapter();
    final chapterRepo = ChapterRepository(dio, offlineDb: dbService);

    // Gọi danh sách chương khi mất mạng -> Fallback về SQLite
    final chapters = await chapterRepo.getChaptersBySeries('series-1');
    expect(chapters.length, 2);
    expect(chapters.first.title, 'Chương 1: Đừng chỉ trích');

    // Gọi chi tiết chương khi mất mạng -> Fallback về SQLite
    final detail = await chapterRepo.getChapterDetail('chap-2');
    expect(detail.isOffline, isTrue);
    expect(detail.title, 'Chương 2: Thành thật khen ngợi');
  });

  test(
    'SeriesRepository tự động fallback getSeriesById về SQLite khi mất mạng',
    () async {
      await dbService.upsertSeries(
        sampleSeries,
        downloadedChaptersCount: 2,
        totalBytes: 120,
        downloadStatus: 'completed',
      );

      final dio = Dio()..httpClientAdapter = _NetworkErrorAdapter();
      final seriesRepo = SeriesRepository(dio, offlineDb: dbService);

      final series = await seriesRepo.getSeriesById('series-1');
      expect(series.id, 'series-1');
      expect(series.title, 'Đắc Nhân Tâm');
      expect(series.genres, ['Kỹ năng sống', 'Tâm lý']);
    },
  );

  test('Ghi nhận tiến độ đọc offline và đánh dấu đã đồng bộ', () async {
    await offlineRepo.saveOfflineProgress(
      seriesId: 'series-1',
      chapterId: 'chap-1',
      sortOrder: 1,
      readPercentage: 0.45,
      isSynced: false,
    );

    final unsynced = await offlineRepo.getUnsyncedProgress();
    expect(unsynced.length, 1);
    expect(unsynced.first.readPercentage, 0.45);

    await offlineRepo.markProgressSynced('series-1');
    final afterSync = await offlineRepo.getUnsyncedProgress();
    expect(afterSync, isEmpty);
  });
}
