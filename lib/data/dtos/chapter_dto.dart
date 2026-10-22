import 'package:flutter/foundation.dart';

/// DTO (Data Transfer Object) - Đối tượng truyền dữ liệu chương
/// Ánh xạ chính xác cấu trúc JSON trả về từ JoyleeBook API Gateway (/api/chapters).
@immutable
class ChapterDto {
  final String id;
  final String seriesId;
  final String? authorId;
  final int sortOrder;
  final String title;
  final int status;
  final DateTime? createdAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  const ChapterDto({
    required this.id,
    required this.seriesId,
    this.authorId,
    required this.sortOrder,
    required this.title,
    required this.status,
    this.createdAt,
    this.publishedAt,
    this.updatedAt,
  });

  factory ChapterDto.fromJson(Map<String, dynamic> json) {
    return ChapterDto(
      id: json['id']?.toString() ?? '',
      seriesId: json['seriesId']?.toString() ?? '',
      authorId: json['authorId']?.toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Chương không tên',
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