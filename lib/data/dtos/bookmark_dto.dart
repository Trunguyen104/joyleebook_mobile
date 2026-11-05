class BookmarkSeriesDto {
  final String seriesId;
  final Map<String, dynamic>? series;

  const BookmarkSeriesDto({required this.seriesId, this.series});

  factory BookmarkSeriesDto.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'] ?? json['Series'];
    final seriesMap = rawSeries is Map
        ? Map<String, dynamic>.from(rawSeries)
        : null;
    final nestedSeriesId =
        seriesMap?['id'] ??
        seriesMap?['Id'] ??
        seriesMap?['seriesId'] ??
        seriesMap?['SeriesId'];

    final resolvedSeriesId =
        (json['seriesId'] ??
                json['SeriesId'] ??
                nestedSeriesId ??
                json['id'] ??
                json['Id'])
            ?.toString() ??
        '';

    return BookmarkSeriesDto(seriesId: resolvedSeriesId, series: seriesMap);
  }

  Map<String, dynamic> toJson() {
    return {'seriesId': seriesId};
  }
}
