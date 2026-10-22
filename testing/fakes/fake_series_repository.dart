import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';

/// FAKE REPOSITORY - Giả lập kho dữ liệu trong bộ nhớ RAM
/// Bước 6 trong kiến trúc Compass App:
/// Giúp viết Unit Test và Widget Test chạy nhanh tức thì mà KHÔNG CẦN backend thật hay kết nối mạng.
class FakeSeriesRepository implements SeriesRepository {
  final List<Series> _items;
  final bool shouldThrowError;

  FakeSeriesRepository([
    List<Series>? initialItems,
    this.shouldThrowError = false,
  ]) : _items = initialItems != null ? List.of(initialItems) : [];

  @override
  Future<List<Series>> getSeriesList({String? searchQuery}) async {
    // Giả lập độ trễ mạng ngắn 50ms
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Lỗi kết nối máy chủ khi tải danh sách.');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      return _items
          .where((s) =>
              s.title.toLowerCase().contains(query) ||
              s.authorName.toLowerCase().contains(query))
          .toList();
    }
    return List.unmodifiable(_items);
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
}
