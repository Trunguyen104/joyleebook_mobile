import 'package:flutter/foundation.dart';

/// DTO (Data Transfer Object) - Đối tượng truyền dữ liệu thể loại
/// Bước 1 trong kiến trúc Compass App:
/// Ánh xạ chính xác cấu trúc JSON trả về từ JoyleeBook Gateway (/api/genres).
/// Tuyệt đối an toàn Null-Safety, không ép kiểu cưỡng bức.
@immutable
class GenreDto {
  final String id;
  final String name;
  final String? description;
  final String? slug;
  final int seriesCount;

  const GenreDto({
    required this.id,
    required this.name,
    this.description,
    this.slug,
    this.seriesCount = 0,
  });

  factory GenreDto.fromJson(Map<String, dynamic> json) {
    return GenreDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Chưa đặt tên',
      description: json['description'] as String?,
      slug: json['slug'] as String?,
      seriesCount:
          (json['seriesCount'] ?? json['totalSeries'] ?? json['count'] as num?)
              ?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (slug != null) 'slug': slug,
      'seriesCount': seriesCount,
    };
  }
}
