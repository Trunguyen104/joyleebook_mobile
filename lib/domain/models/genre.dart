import 'package:flutter/foundation.dart';

import '../../data/dtos/genre_dto.dart';

/// PURE DOMAIN MODEL - Thực thể nghiệp vụ Thể loại
/// Bước 2 trong kiến trúc Compass App:
/// Lớp đối tượng thuần túy (Pure Dart), bất biến (@immutable).
/// Không phụ thuộc vào thư viện UI (Material) hay mạng (Dio).
@immutable
class Genre {
  final String id;
  final String name;
  final String? description;
  final String? slug;
  final int seriesCount;

  const Genre({
    required this.id,
    required this.name,
    this.description,
    this.slug,
    this.seriesCount = 0,
  });

  /// Factory chuyển đổi an toàn từ DTO sang Domain Model
  factory Genre.fromDto(GenreDto dto) {
    return Genre(
      id: dto.id,
      name: dto.name.trim().isNotEmpty ? dto.name.trim() : 'Chưa đặt tên',
      description: (dto.description != null && dto.description!.trim().isNotEmpty)
          ? dto.description!.trim()
          : null,
      slug: dto.slug,
      seriesCount: dto.seriesCount,
    );
  }

  /// Tạo bản sao với các thuộc tính tùy chọn được cập nhật
  Genre copyWith({
    String? id,
    String? name,
    String? description,
    String? slug,
    int? seriesCount,
  }) {
    return Genre(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      seriesCount: seriesCount ?? this.seriesCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Genre &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'Genre(id: $id, name: $name, seriesCount: $seriesCount)';
}
