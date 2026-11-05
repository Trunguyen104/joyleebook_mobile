import 'package:flutter/foundation.dart';

@immutable
class ReadingProgressDto {
  final double? progress;

  const ReadingProgressDto({this.progress});

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
      if (value is num) {
        return ReadingProgressDto(progress: _normalize(value));
      }
      if (value is Map) return ReadingProgressDto.fromJson(value);
      if (value == null) return const ReadingProgressDto();
    }

    throw const FormatException('Dữ liệu tiến độ đọc không đúng định dạng.');
  }

  static double _normalize(num value) {
    final amount = value.toDouble();
    return (amount > 1 ? amount / 100 : amount).clamp(0.0, 1.0);
  }
}
