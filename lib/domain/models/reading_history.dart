import 'package:flutter/foundation.dart';

import '../../data/dtos/reading_history_dto.dart';
import 'series.dart';

@immutable
class ReadingHistory {
  final String seriesId;
  final Series series;
  final String? chapterId;
  final String? chapterTitle;
  final int? chapterNumber;
  final double? progress;
  final DateTime? lastReadAt;

  const ReadingHistory({
    required this.seriesId,
    required this.series,
    this.chapterId,
    this.chapterTitle,
    this.chapterNumber,
    this.progress,
    this.lastReadAt,
  });

  factory ReadingHistory.fromDto(ReadingHistoryDto dto) => ReadingHistory(
    seriesId: dto.seriesId,
    series: Series.fromDto(dto.series),
    chapterId: dto.chapterId,
    chapterTitle: dto.chapterTitle,
    chapterNumber: dto.chapterNumber,
    progress: dto.progress,
    lastReadAt: dto.lastReadAt,
  );
}
