import 'package:flutter/foundation.dart';

@immutable
class ReadingProgressDto {
  final double? progress;
  final String? seriesId;
  final String? chapterId;
  final int? chapterSortOrder;
  final bool? isCompleted;
  final DateTime? lastReadAtUtc;

  const ReadingProgressDto({
    this.progress,
    this.seriesId,
    this.chapterId,
    this.chapterSortOrder,
    this.isCompleted,
    this.lastReadAtUtc,
  });

  factory ReadingProgressDto.fromJson(dynamic json) {
    if (json == null) return const ReadingProgressDto();
    if (json is num) return ReadingProgressDto(progress: _normalize(json));
    if (json is Map) {
      final data = json['data'] ?? json['Data'];
      if (data != null) return ReadingProgressDto.fromJson(data);

      final value =
          json['progressPercentage'] ??
          json['ProgressPercentage'] ??
          json['readPercentage'] ??
          json['ReadPercentage'] ??
          json['scrollPercentage'] ??
          json['ScrollPercentage'] ??
          json['percentage'] ??
          json['Percentage'] ??
          json['progress'] ??
          json['Progress'];

      double? normalizedProgress;
      if (value is num) {
        normalizedProgress = _normalize(value);
      } else if (value is Map) {
        normalizedProgress = ReadingProgressDto.fromJson(value).progress;
      }

      final rawSortOrder =
          json['chapterSortOrder'] ??
          json['ChapterSortOrder'] ??
          json['sortOrder'] ??
          json['SortOrder'];
      final rawCompleted = json['isCompleted'] ?? json['IsCompleted'];
      final rawLastReadAt =
          json['lastReadAtUtc'] ??
          json['LastReadAtUtc'] ??
          json['lastReadAt'] ??
          json['LastReadAt'];

      return ReadingProgressDto(
        progress: normalizedProgress,
        seriesId: (json['seriesId'] ?? json['SeriesId'])?.toString(),
        chapterId: (json['chapterId'] ?? json['ChapterId'])?.toString(),
        chapterSortOrder: _readInt(rawSortOrder),
        isCompleted: _readBool(rawCompleted),
        lastReadAtUtc: rawLastReadAt == null
            ? null
            : DateTime.tryParse(rawLastReadAt.toString()),
      );
    }

    throw const FormatException('Dữ liệu tiến độ đọc không đúng định dạng.');
  }

  static int? _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return null;
  }

  static double _normalize(num value) {
    final amount = value.toDouble();
    return (amount > 1 ? amount / 100 : amount).clamp(0.0, 1.0);
  }
}
