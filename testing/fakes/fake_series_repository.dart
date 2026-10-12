import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';

/// FAKE REPOSITORY - Giả lập kho dữ liệu trong bộ nhớ RAM
/// Bước 6 trong kiến trúc Compass App:
/// Giúp viết Unit Test và Widget Test chạy nhanh tức thì mà KHÔNG CẦN backend thật hay kết nối mạng.
class FakeSeriesRepository implements SeriesRepository {
  final List<Series> _items;

  FakeSeriesRepository([List<Series>? initialItems])
      : _items = initialItems ?? [];

  @override
  Future<List<Series>> getSeriesList({String? searchQuery}) async {
    // Giả lập độ trễ mạng ngắn 50ms
    await Future<void>.delayed(const Duration(milliseconds: 50));

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
  Future<void> toggleBookmark(String seriesId, bool shouldBookmark) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final index = _items.indexWhere((s) => s.id == seriesId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isBookmarked: shouldBookmark);
    }
  }
}
