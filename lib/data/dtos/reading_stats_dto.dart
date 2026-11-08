import 'package:flutter/foundation.dart';

/// DTO cho `GET /api/library/stats?days=30&utcOffsetMinutes=420` (cần Bearer token).
/// Bỏ qua 2 mảng `dailyActivity` và `topSeries` vì màn Hồ sơ chưa dùng.
@immutable
class ReadingStatsDto {
  /// Số truyện đã bắt đầu đọc
  final int seriesStarted;

  /// Tổng số chương đã đọc xong
  final int chaptersCompleted;

  /// Số ngày của kỳ thống kê (tham số `days`)
  final int periodDays;

  /// Số chương đọc xong trong kỳ
  final int chaptersCompletedInPeriod;

  /// Số ngày có đọc trong kỳ
  final int activeDaysInPeriod;

  /// Chuỗi ngày đọc liên tiếp hiện tại
  final int currentStreakDays;

  /// Chuỗi ngày đọc liên tiếp dài nhất
  final int longestStreakDays;

  /// Lần đọc gần nhất (null nếu chưa đọc chương nào)
  final DateTime? lastReadAtUtc;

  const ReadingStatsDto({
    this.seriesStarted = 0,
    this.chaptersCompleted = 0,
    this.periodDays = 0,
    this.chaptersCompletedInPeriod = 0,
    this.activeDaysInPeriod = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.lastReadAtUtc,
  });

  factory ReadingStatsDto.fromJson(Map<String, dynamic> json) {
    // Đọc số an toàn: chấp nhận cả int lẫn double, thiếu trường thì về 0
    int readInt(String key) => (json[key] as num?)?.toInt() ?? 0;

    return ReadingStatsDto(
      seriesStarted: readInt('seriesStarted'),
      chaptersCompleted: readInt('chaptersCompleted'),
      periodDays: readInt('periodDays'),
      chaptersCompletedInPeriod: readInt('chaptersCompletedInPeriod'),
      activeDaysInPeriod: readInt('activeDaysInPeriod'),
      currentStreakDays: readInt('currentStreakDays'),
      longestStreakDays: readInt('longestStreakDays'),
      lastReadAtUtc: DateTime.tryParse(json['lastReadAtUtc']?.toString() ?? ''),
    );
  }
}
