import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/data/dtos/upsert_reading_progress_dto.dart';
import 'package:joyleebook_mobile/domain/models/reading_history.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';

/// FAKE REPOSITORY - Giả lập kho dữ liệu trong bộ nhớ RAM
/// Bước 6 trong kiến trúc Compass App:
/// Giúp viết Unit Test và Widget Test chạy nhanh tức thì mà KHÔNG CẦN backend thật hay kết nối mạng.
class FakeSeriesRepository implements SeriesRepository {
  final List<Series> _items;
  final bool shouldThrowError;
  final List<ReadingHistory> _readingHistory;
  int bookmarkListCallCount = 0;
  int readingProgressCallCount = 0;
  int readingProgressUpdateCount = 0;
  UpsertReadingProgressDto? lastReadingProgressUpdate;

  FakeSeriesRepository([
    List<Series>? initialItems,
    this.shouldThrowError = false,
  ]) : _items = initialItems != null ? List.of(initialItems) : [],
       _readingHistory = const [];

  FakeSeriesRepository.withHistory(
    List<Series>? initialItems, {
    this.shouldThrowError = false,
    this._readingHistory = const [],
  }) : _items = initialItems != null ? List.of(initialItems) : [];

  @override
  Future<List<Series>> getSeriesList({
    String? searchQuery,
    String? genre,
    SeriesStatus? status,
  }) async {
    // Giả lập độ trễ mạng ngắn 50ms
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Lỗi kết nối máy chủ khi tải danh sách.');
    }

    var result = List<Series>.of(_items);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result
          .where(
            (s) =>
                s.title.toLowerCase().contains(query) ||
                s.authorName.toLowerCase().contains(query),
          )
          .toList();
    }

    if (genre != null && genre.trim().isNotEmpty) {
      final targetGenre = genre.trim().toLowerCase();
      result = result
          .where(
            (s) => s.genres.any(
              (g) =>
                  g.toLowerCase() == targetGenre ||
                  g.toLowerCase().contains(targetGenre),
            ),
          )
          .toList();
    }

    if (status != null) {
      result = result.where((s) => s.status == status).toList();
    }

    return List.unmodifiable(result);
  }

  @override
  Future<Series> getSeriesById(String seriesId) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Không thể tải chi tiết tác phẩm.');
    }
    final item = _items.where((s) => s.id == seriesId).firstOrNull;
    if (item != null) return item;
    throw AppException(message: 'Không tìm thấy tác phẩm.');
  }

  @override
  Future<List<Series>> getBookmarkedSeries() async {
    bookmarkListCallCount++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Không thể tải tủ sách cá nhân.');
    }
    return List.unmodifiable(_items.where((series) => series.isBookmarked));
  }

  @override
  Future<List<ReadingHistory>> getReadingHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Không thể tải lịch sử đọc.');
    }
    return List.unmodifiable(_readingHistory);
  }

  @override
  Future<double?> getReadingProgress(String seriesId) async {
    readingProgressCallCount++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Không thể tải tiến độ đọc.');
    }
    return _readingHistory
        .where((entry) => entry.seriesId == seriesId)
        .firstOrNull
        ?.progress;
  }

  @override
  Future<void> updateReadingProgress(UpsertReadingProgressDto progress) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Không thể cập nhật tiến độ đọc.');
    }
    readingProgressUpdateCount++;
    lastReadingProgressUpdate = progress;
  }

  @override
  Future<bool> getBookmarkStatus(String seriesId) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Không thể kiểm tra trạng thái tủ sách.');
    }
    return _items
            .where((series) => series.id == seriesId)
            .firstOrNull
            ?.isBookmarked ??
        false;
  }

  @override
  Future<void> toggleBookmark(String seriesId, bool shouldBookmark) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Lỗi khi cập nhật tủ sách.');
    }
    final index = _items.indexWhere((s) => s.id == seriesId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isBookmarked: shouldBookmark);
    }
  }

  @override
  Future<void> rateSeries(String seriesId, int score) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Lỗi khi gửi đánh giá tác phẩm.');
    }
    if (score < 1 || score > 5) {
      throw AppException(
        message: 'Điểm đánh giá không hợp lệ. Vui lòng chọn từ 1 đến 5 sao.',
      );
    }
    final index = _items.indexWhere((s) => s.id == seriesId);
    if (index != -1) {
      final old = _items[index];
      final isFirstRate = old.userRating == null;
      final newTotal = isFirstRate ? old.totalRatings + 1 : old.totalRatings;
      final currentSum = old.averageRating * old.totalRatings;
      final newSum = isFirstRate
          ? (currentSum + score)
          : (currentSum - (old.userRating ?? 0) + score);
      final newAvg = newTotal > 0 ? (newSum / newTotal) : score.toDouble();

      _items[index] = old.copyWith(
        userRating: score,
        totalRatings: newTotal,
        averageRating: double.parse(newAvg.toStringAsFixed(1)),
      );
    }
  }
}
