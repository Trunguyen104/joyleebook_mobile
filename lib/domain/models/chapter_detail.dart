import 'package:flutter/foundation.dart';
import '../../data/dtos/chapter_detail_dto.dart';

/// PURE DOMAIN MODEL - Chi tiết nội dung một chương đọc
@immutable
class ChapterDetail {
  final String id;
  final String seriesId;
  final String title;
  final String content;
  final int sortOrder;
  final int totalChapters;
  final int status;
  final DateTime? publishedAt;

  const ChapterDetail({
    required this.id,
    required this.seriesId,
    required this.title,
    required this.content,
    required this.sortOrder,
    required this.totalChapters,
    required this.status,
    this.publishedAt,
  });

  factory ChapterDetail.fromDto(ChapterDetailDto dto) {
    return ChapterDetail(
      id: dto.id,
      seriesId: dto.seriesId,
      title: dto.title.isNotEmpty ? dto.title : 'Chương ${dto.sortOrder}',
      content: dto.content,
      sortOrder: dto.sortOrder,
      totalChapters: dto.totalChapters,
      status: dto.status,
      publishedAt: dto.publishedAt,
    );
  }

  /// Có chương trước đó hay không
  bool get hasPrevious => sortOrder > 1;

  /// Có chương kế tiếp hay không
  bool get hasNext => sortOrder < totalChapters;

  /// Đếm số từ ước tính
  int get wordCount => content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

  /// Thời gian đọc ước tính (khoảng 200 từ/phút)
  int get estimatedReadingMinutes {
    final words = wordCount;
    return (words / 200).ceil().clamp(1, 120);
  }
}
