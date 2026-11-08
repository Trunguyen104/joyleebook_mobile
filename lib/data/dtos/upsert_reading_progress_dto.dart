class UpsertReadingProgressDto {
  final String seriesId;
  final String chapterId;
  final int chapterSortOrder;
  final double scrollPercentage;
  final bool isCompleted;
  final DateTime? readAtUtc;

  const UpsertReadingProgressDto({
    required this.seriesId,
    required this.chapterId,
    this.chapterSortOrder = 0,
    this.scrollPercentage = 0,
    this.isCompleted = false,
    this.readAtUtc,
  });

  Map<String, dynamic> toJson() => {
    'seriesId': seriesId,
    'chapterId': chapterId,
    'chapterSortOrder': chapterSortOrder,
    'scrollPercentage': scrollPercentage,
    'isCompleted': isCompleted,
    if (readAtUtc != null) 'readAtUtc': readAtUtc!.toUtc().toIso8601String(),
  };
}
