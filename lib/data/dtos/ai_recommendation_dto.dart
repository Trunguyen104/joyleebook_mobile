import 'package:flutter/foundation.dart';

import 'series_dto.dart';

/// DTO trích xuất từ phản hồi Semantic Search (/api/series/semantic-search)
@immutable
class SemanticSearchItemDto {
  final SeriesDto series;
  final double relevanceScore;

  const SemanticSearchItemDto({
    required this.series,
    required this.relevanceScore,
  });

  factory SemanticSearchItemDto.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'] ?? json['Series'];
    final seriesMap = rawSeries is Map<String, dynamic>
        ? rawSeries
        : (rawSeries is Map
              ? Map<String, dynamic>.from(rawSeries)
              : <String, dynamic>{});

    final rawScore =
        json['relevanceScore'] ??
        json['RelevanceScore'] ??
        json['score'] ??
        json['Score'];
    final score = (rawScore is num) ? rawScore.toDouble() : 0.0;

    return SemanticSearchItemDto(
      series: SeriesDto.fromJson(seriesMap),
      relevanceScore: score,
    );
  }
}

@immutable
class SemanticSearchResponseDto {
  final String query;
  final int totalFound;
  final List<SemanticSearchItemDto> items;

  const SemanticSearchResponseDto({
    required this.query,
    required this.totalFound,
    required this.items,
  });

  factory SemanticSearchResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'] ?? [];
    final itemsList = (rawItems is List)
        ? rawItems
              .whereType<Map>()
              .map(
                (e) => SemanticSearchItemDto.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <SemanticSearchItemDto>[];

    return SemanticSearchResponseDto(
      query: (json['query'] ?? json['Query'])?.toString() ?? '',
      totalFound:
          (json['totalFound'] ?? json['TotalFound'] as num?)?.toInt() ??
          itemsList.length,
      items: itemsList,
    );
  }
}

/// DTO trích xuất từ phản hồi Similar Series (/api/series/{id}/similar)
@immutable
class SimilarSeriesItemDto {
  final SeriesDto series;
  final double? similarityScore;

  const SimilarSeriesItemDto({required this.series, this.similarityScore});

  factory SimilarSeriesItemDto.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'] ?? json['Series'];
    final seriesMap = rawSeries is Map<String, dynamic>
        ? rawSeries
        : (rawSeries is Map
              ? Map<String, dynamic>.from(rawSeries)
              : <String, dynamic>{});

    final rawScore =
        json['similarityScore'] ??
        json['SimilarityScore'] ??
        json['score'] ??
        json['Score'];
    final score = (rawScore is num) ? rawScore.toDouble() : null;

    return SimilarSeriesItemDto(
      series: SeriesDto.fromJson(seriesMap),
      similarityScore: score,
    );
  }
}

@immutable
class SimilarSeriesListResponseDto {
  final String sourceSeriesId;
  final bool isFallbackByGenre;
  final List<SimilarSeriesItemDto> items;

  const SimilarSeriesListResponseDto({
    required this.sourceSeriesId,
    required this.isFallbackByGenre,
    required this.items,
  });

  factory SimilarSeriesListResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'] ?? [];
    final itemsList = (rawItems is List)
        ? rawItems
              .whereType<Map>()
              .map(
                (e) =>
                    SimilarSeriesItemDto.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <SimilarSeriesItemDto>[];

    return SimilarSeriesListResponseDto(
      sourceSeriesId:
          (json['sourceSeriesId'] ?? json['SourceSeriesId'])?.toString() ?? '',
      isFallbackByGenre:
          (json['isFallbackByGenre'] ?? json['IsFallbackByGenre']) as bool? ??
          false,
      items: itemsList,
    );
  }
}
