import 'package:flutter/foundation.dart';

/// DTO (Data Transfer Object) - Chi tiết nội dung chương truyện
/// Ánh xạ từ endpoint `GET /api/chapters/{chapterId}` từ JoyleeBook API Gateway.
@immutable
class ChapterDetailDto {
  final String id;
  final String seriesId;
  final String? authorId;
  final String title;
  final String content;
  final int sortOrder;
  final int totalChapters;
  final int status;
  final DateTime? createdAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  const ChapterDetailDto({
    required this.id,
    required this.seriesId,
    this.authorId,
    required this.title,
    required this.content,
    required this.sortOrder,
    required this.totalChapters,
    required this.status,
    this.createdAt,
    this.publishedAt,
    this.updatedAt,
  });

  factory ChapterDetailDto.fromJson(Map<String, dynamic> json) {
    return ChapterDetailDto(
      id: json['id']?.toString() ?? '',
      seriesId: json['seriesId']?.toString() ?? '',
      authorId: json['authorId']?.toString(),
      title: json['title'] as String? ?? 'Chương không tên',
      content: json['content'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 1,
      totalChapters: (json['totalChapters'] as num?)?.toInt() ?? 1,
      status: (json['status'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
