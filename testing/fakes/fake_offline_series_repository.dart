import 'package:joyleebook_mobile/data/repositories/offline_series_repository.dart';
import 'package:joyleebook_mobile/data/services/reading_preferences_service.dart';
import 'package:joyleebook_mobile/domain/models/chapter.dart';
import 'package:joyleebook_mobile/domain/models/chapter_detail.dart';
import 'package:joyleebook_mobile/domain/models/downloaded_series.dart';

/// FAKE REPOSITORY - Giả lập dữ liệu đọc ngoại tuyến trong bộ nhớ cho Unit & Widget Tests
class FakeOfflineSeriesRepository implements OfflineSeriesRepository {
  final List<DownloadedSeries> _seriesList;
  final Map<String, List<Chapter>> _chaptersMap;
  final Map<String, ChapterDetail> _detailsMap;
  final Map<String, LocalReadingProgress> _progressMap = {};
  final Set<String> _unsyncedIds = {};
  final bool shouldThrowError;

  FakeOfflineSeriesRepository({
    List<DownloadedSeries> seriesList = const [],
    Map<String, List<Chapter>> chaptersMap = const {},
    Map<String, ChapterDetail> detailsMap = const {},
    this.shouldThrowError = false,
  }) : _seriesList = List.of(seriesList),
       _chaptersMap = Map.of(chaptersMap),
       _detailsMap = Map.of(detailsMap);

  @override
  Future<List<DownloadedSeries>> getDownloadedSeriesList({
    bool onlyCompleted = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (shouldThrowError) {
      throw Exception('Lỗi đọc cơ sở dữ liệu offline giả lập.');
    }
    return List.unmodifiable(_seriesList);
  }

  @override
  Future<DownloadedSeries?> getDownloadedSeries(String seriesId) async {
    return _seriesList.where((s) => s.id == seriesId).firstOrNull;
  }

  @override
  Future<List<Chapter>> getDownloadedChapters(String seriesId) async {
    return _chaptersMap[seriesId] ?? const [];
  }

  @override
  Future<ChapterDetail?> getDownloadedChapterDetail(String chapterId) async {
    return _detailsMap[chapterId];
  }

  @override
  Future<bool> isSeriesDownloaded(String seriesId) async {
    return _seriesList.any((s) => s.id == seriesId);
  }

  @override
  Future<bool> isChapterDownloaded(String chapterId) async {
    return _detailsMap.containsKey(chapterId);
  }

  @override
  Future<Set<String>> getDownloadedChapterIds(String seriesId) async {
    return (_chaptersMap[seriesId] ?? const []).map((c) => c.id).toSet();
  }

  @override
  Future<int> getTotalDownloadedBytes() async {
    return _seriesList.fold<int>(0, (sum, item) => sum + item.totalBytes);
  }

  @override
  Future<void> deleteDownloadedSeries(String seriesId) async {
    if (shouldThrowError) throw Exception('Lỗi xóa giả lập.');
    _seriesList.removeWhere((s) => s.id == seriesId);
    _chaptersMap.remove(seriesId);
  }

  @override
  Future<void> deleteAllDownloads() async {
    if (shouldThrowError) throw Exception('Lỗi xóa tất cả giả lập.');
    _seriesList.clear();
    _chaptersMap.clear();
    _detailsMap.clear();
  }

  @override
  Future<void> saveOfflineProgress({
    required String seriesId,
    required String chapterId,
    required int sortOrder,
    required double readPercentage,
    bool isSynced = false,
  }) async {
    _progressMap[seriesId] = LocalReadingProgress(
      seriesId: seriesId,
      chapterId: chapterId,
      sortOrder: sortOrder,
      readPercentage: readPercentage,
      updatedAt: DateTime.now(),
    );
    if (!isSynced) {
      _unsyncedIds.add(seriesId);
    } else {
      _unsyncedIds.remove(seriesId);
    }
  }

  @override
  Future<LocalReadingProgress?> getOfflineProgress(String seriesId) async {
    return _progressMap[seriesId];
  }

  @override
  Future<List<LocalReadingProgress>> getUnsyncedProgress() async {
    return _unsyncedIds
        .map((id) => _progressMap[id])
        .whereType<LocalReadingProgress>()
        .toList();
  }

  @override
  Future<void> markProgressSynced(String seriesId) async {
    _unsyncedIds.remove(seriesId);
  }
}
