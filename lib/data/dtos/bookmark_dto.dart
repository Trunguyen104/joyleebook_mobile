class BookmarkSeriesDto {
  final String seriesId;
  final Map<String, dynamic>? series;

  const BookmarkSeriesDto({required this.seriesId, this.series});

  factory BookmarkSeriesDto.fromJson(Map<String, dynamic> json) {
    final series = json['series'];
    final nestedSeriesId = series is Map<String, dynamic> ? series['id'] : null;
    return BookmarkSeriesDto(
      seriesId:
          (json['seriesId'] ?? json['id'] ?? nestedSeriesId)?.toString() ?? '',
      series: series is Map<String, dynamic> ? series : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'seriesId': seriesId};
  }
}
