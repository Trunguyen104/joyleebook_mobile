import 'package:flutter/foundation.dart';
import '../../data/dtos/chapter_dto.dart';

/// PURE DOMAIN MODEL - Thực thể nghiệp vụ thuần túy của một chương sách
/// Không phụ thuộc vào thư viện ngoài hay giao diện.
@immutable
class Chapter {
  final String id;
  final String seriesId;
  final int sortOrder;
  final String title;
  final bool isFree;
  final int durationMinutes;
  final double readPercentage; // 0.0 -> 1.0 (ví dụ 0.45 là 45%)
  final bool isCompleted;
  final bool isActive;

  const Chapter({
    required this.id,
    required this.seriesId,
    required this.sortOrder,
    required this.title,
    this.isFree = true,
    this.durationMinutes = 15,
    this.readPercentage = 0.0,
    this.isCompleted = false,
    this.isActive = false,
  });

  /// Chuyển đổi từ ChapterDto sang Chapter Domain Model
  factory Chapter.fromDto(
    ChapterDto dto, {
    double readPercentage = 0.0,
    bool isCompleted = false,
    bool isActive = false,
  }) {
    return Chapter(
      id: dto.id,
      seriesId: dto.seriesId,
      sortOrder: dto.sortOrder,
      title: dto.title.isNotEmpty ? dto.title : 'Chương ${dto.sortOrder}',
      // Giả định nghiệp vụ: 3 chương đầu là miễn phí
      isFree: dto.sortOrder <= 3,
      // Tính thời lượng đọc ước tính (trung bình 12-18 phút)
      durationMinutes: 12 + (dto.sortOrder % 7),
      readPercentage: readPercentage,
      isCompleted: isCompleted,
      isActive: isActive,
    );
  }

  Chapter copyWith({
    String? id,
    String? seriesId,
    int? sortOrder,
    String? title,
    bool? isFree,
    int? durationMinutes,
    double? readPercentage,
    bool? isCompleted,
    bool? isActive,
  }) {
    return Chapter(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      sortOrder: sortOrder ?? this.sortOrder,
      title: title ?? this.title,
      isFree: isFree ?? this.isFree,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      readPercentage: readPercentage ?? this.readPercentage,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
    );
  }
}