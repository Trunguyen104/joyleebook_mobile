import 'package:flutter/foundation.dart';

import 'series_dto.dart';

@immutable
class ReadingHistoryDto {
  final String seriesId;
  final SeriesDto series;
  final String? chapterId;
  final String? chapterTitle;
  final int? chapterNumber;
  final double? progress;
  final DateTime? lastReadAt;

  const ReadingHistoryDto({
    required this.seriesId,
    required this.series,
    this.chapterId,
    this.chapterTitle,
    this.chapterNumber,
    this.progress,
    this.lastReadAt,
  });

  factory ReadingHistoryDto.fromJson(Map<String, dynamic> json) {
    final rawSeries = _asMap(json['series'] ?? json['Series']);
    final rawChapter = _asMap(
      json['chapter'] ??
          json['Chapter'] ??
          json['lastReadChapter'] ??
          json['LastReadChapter'],
    );
    final seriesId =
        (json['seriesId'] ??
                json['SeriesId'] ??
                rawSeries?['id'] ??
                rawSeries?['seriesId'] ??
                json['id'])
            ?.toString() ??
        '';
    final progress = json['progress'] ?? json['Progress'];
    final progressMap = _asMap(progress);
    final rawProgress =
        progressMap?['percentage'] ??
        progressMap?['Percentage'] ??
        progressMap?['progressPercentage'] ??
        progressMap?['ProgressPercentage'] ??
        progressMap?['readPercentage'] ??
        progressMap?['ReadPercentage'] ??
        progressMap?['scrollPercentage'] ??
        progressMap?['ScrollPercentage'] ??
        progressMap?['progress'] ??
        progressMap?['Progress'] ??
        json['progressPercentage'] ??
        json['ProgressPercentage'] ??
        json['readPercentage'] ??
        json['ReadPercentage'] ??
        json['scrollPercentage'] ??
        json['ScrollPercentage'] ??
        (progress is num ? progress : null);

    final seriesJson = Map<String, dynamic>.from(rawSeries ?? json)
      ..['id'] = seriesId
      ..['title'] =
          rawSeries?['title'] ??
          rawSeries?['Title'] ??
          json['seriesTitle'] ??
          json['SeriesTitle'] ??
          json['title'] ??
          json['Title']
      ..['coverImageUrl'] =
          rawSeries?['coverImageUrl'] ??
          rawSeries?['CoverImageUrl'] ??
          rawSeries?['coverUrl'] ??
          rawSeries?['CoverUrl'] ??
          json['coverImageUrl'] ??
          json['CoverImageUrl'] ??
          json['coverUrl'] ??
          json['CoverUrl']
      ..['authorId'] = rawSeries?['authorId'] ?? rawSeries?['AuthorId']
      ..['authorName'] =
          rawSeries?['authorName'] ??
          rawSeries?['AuthorName'] ??
          json['authorName'] ??
          json['AuthorName'];

    return ReadingHistoryDto(
      seriesId: seriesId,
      series: SeriesDto.fromJson(seriesJson),
      chapterId:
          (json['chapterId'] ??
                  json['ChapterId'] ??
                  rawChapter?['id'] ??
                  rawChapter?['chapterId'] ??
                  rawChapter?['ChapterId'])
              ?.toString(),
      chapterTitle:
          (json['chapterTitle'] ??
                  json['ChapterTitle'] ??
                  rawChapter?['title'] ??
                  rawChapter?['Title'])
              as String?,
      chapterNumber: _readInt(
        json['chapterNumber'] ??
            json['ChapterNumber'] ??
            json['sortOrder'] ??
            json['SortOrder'] ??
            json['chapterSortOrder'] ??
            json['ChapterSortOrder'] ??
            rawChapter?['sortOrder'] ??
            rawChapter?['SortOrder'] ??
            rawChapter?['chapterSortOrder'] ??
            rawChapter?['ChapterSortOrder'] ??
            rawChapter?['chapterNumber'] ??
            rawChapter?['ChapterNumber'],
      ),
      progress: _readProgress(rawProgress),
      lastReadAt: DateTime.tryParse(
        (json['lastReadAt'] ??
                    json['lastReadAtUtc'] ??
                    json['LastReadAt'] ??
                    json['LastReadAtUtc'] ??
                    json['updatedAt'] ??
                    json['UpdatedAt'])
                ?.toString() ??
            '',
      ),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int? _readInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static double? _readProgress(dynamic value) {
    if (value is! num) return null;
    final amount = value.toDouble();
    return (amount > 1 ? amount / 100 : amount).clamp(0.0, 1.0);
  }
}
