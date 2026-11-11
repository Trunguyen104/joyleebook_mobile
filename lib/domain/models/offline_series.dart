import 'package:flutter/foundation.dart';

import 'offline_chapter.dart';

/// Một bộ truyện có ít nhất một chương đã được tải về thiết bị.
@immutable
class OfflineSeries {
  final String userId;
  final String id;
  final String title;
  final String authorName;
  final String coverImageUrl;
  final int status;
  final int totalChapters;
  final DateTime updatedAt;
  final List<OfflineChapter> chapters;

  const OfflineSeries({
    required this.userId,
    required this.id,
    required this.title,
    required this.authorName,
    required this.coverImageUrl,
    required this.status,
    required this.totalChapters,
    required this.updatedAt,
    required this.chapters,
  });
}
