import 'package:flutter/foundation.dart';

import 'series.dart';

/// PURE DOMAIN MODEL - Tác phẩm đã được tải về lưu trữ cục bộ
@immutable
class DownloadedSeries {
  final String id;
  final String title;
  final String authorName;
  final String description;
  final String? coverLocalPath;
  final String coverImageUrl;
  final SeriesStatus status;
  final List<String> genres;
  final int totalChapters;
  final int downloadedChaptersCount;
  final int totalBytes;
  final DateTime downloadedAt;
  final DateTime? updatedAt;

  const DownloadedSeries({
    required this.id,
    required this.title,
    required this.authorName,
    required this.description,
    this.coverLocalPath,
    required this.coverImageUrl,
    required this.status,
    this.genres = const [],
    required this.totalChapters,
    required this.downloadedChaptersCount,
    required this.totalBytes,
    required this.downloadedAt,
    this.updatedAt,
  });

  /// Định dạng dung lượng sang KB hoặc MB
  String get formattedSize {
    if (totalBytes <= 0) return '0 KB';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Chuyển đổi thành Series model để tái sử dụng giao diện
  Series toSeries() {
    return Series(
      id: id,
      title: title,
      authorName: authorName,
      description: description,
      coverImageUrl: coverImageUrl,
      status: status,
      genres: genres,
      totalChapters: totalChapters,
    );
  }
}
