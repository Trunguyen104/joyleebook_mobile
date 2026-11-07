import 'package:flutter/foundation.dart';

/// PURE DOMAIN MODEL - Tiến độ đọc của một bộ truyện lấy từ Library API.
@immutable
class ReadingProgress {
  final String? seriesId;
  final String? chapterId;
  final int? chapterSortOrder;
  final double progress; // 0.0 -> 1.0
  final bool isCompleted;
  final DateTime? lastReadAtUtc;

  const ReadingProgress({
    this.seriesId,
    this.chapterId,
    this.chapterSortOrder,
    this.progress = 0.0,
    this.isCompleted = false,
    this.lastReadAtUtc,
  });
}
