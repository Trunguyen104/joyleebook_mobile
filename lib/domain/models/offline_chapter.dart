import 'package:flutter/foundation.dart';

/// Nội dung chương đã tải về thiết bị để đọc khi mất kết nối.
@immutable
class OfflineChapter {
  final String userId;
  final String id;
  final String seriesId;
  final String seriesTitle;
  final String title;
  final String content;
  final int sortOrder;
  final int totalChapters;
  final int status;
  final DateTime? publishedAt;
  final DateTime downloadedAt;
  final DateTime? serverUpdatedAt;

  const OfflineChapter({
    required this.userId,
    required this.id,
    required this.seriesId,
    required this.seriesTitle,
    required this.title,
    required this.content,
    required this.sortOrder,
    required this.totalChapters,
    required this.status,
    required this.publishedAt,
    required this.downloadedAt,
    required this.serverUpdatedAt,
  });
}
