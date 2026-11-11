import 'package:flutter/foundation.dart';

/// PURE DOMAIN MODEL - Các tùy chọn sắp xếp cho màn hình Tìm kiếm & Khám phá
enum SearchSortOption {
  relevance('Phù hợp nhất'),
  newest('Mới cập nhật'),
  mostRead('Lượt đọc nhiều'),
  topRated('Đánh giá cao');

  final String label;

  const SearchSortOption(this.label);
}

/// Loại gợi ý tìm kiếm khi người dùng đang nhập từ khóa
enum SearchSuggestionType { series, author, genre, aiSemantic }

/// PURE DOMAIN MODEL - Một mục gợi ý tìm kiếm khi đang gõ
@immutable
class SearchSuggestion {
  final String text;
  final String? subtitle;
  final SearchSuggestionType type;
  final String? seriesId;

  const SearchSuggestion({
    required this.text,
    this.subtitle,
    required this.type,
    this.seriesId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSuggestion &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          subtitle == other.subtitle &&
          type == other.type &&
          seriesId == other.seriesId;

  @override
  int get hashCode => Object.hash(text, subtitle, type, seriesId);
}
