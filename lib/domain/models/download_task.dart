import 'package:flutter/foundation.dart';

/// Trạng thái của một tiến trình tải truyện
enum DownloadStatus {
  idle,
  queued,
  downloading,
  paused,
  completed,
  failed;

  String get label => switch (this) {
    DownloadStatus.idle => 'Chưa tải',
    DownloadStatus.queued => 'Đang chờ tải',
    DownloadStatus.downloading => 'Đang tải về',
    DownloadStatus.paused => 'Tạm dừng',
    DownloadStatus.completed => 'Đã tải xong',
    DownloadStatus.failed => 'Tải thất bại',
  };

  bool get isTerminal => this == completed || this == failed;
  bool get isActive => this == queued || this == downloading;
}

/// PURE DOMAIN MODEL - Trạng thái tác vụ tải truyện ngoại tuyến
@immutable
class DownloadTask {
  final String seriesId;
  final String seriesTitle;
  final int totalChapters;
  final int downloadedChapters;
  final int downloadedBytes;
  final DownloadStatus status;
  final String? errorMessage;
  final DateTime? startedAt;

  const DownloadTask({
    required this.seriesId,
    required this.seriesTitle,
    required this.totalChapters,
    this.downloadedChapters = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.idle,
    this.errorMessage,
    this.startedAt,
  });

  double get progressPercentage {
    if (totalChapters <= 0) return 0.0;
    return (downloadedChapters / totalChapters).clamp(0.0, 1.0);
  }

  String get formattedProgress => '$downloadedChapters/$totalChapters chương';

  String get formattedBytes {
    if (downloadedBytes <= 0) return '0 KB';
    if (downloadedBytes < 1024 * 1024) {
      return '${(downloadedBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  DownloadTask copyWith({
    int? totalChapters,
    int? downloadedChapters,
    int? downloadedBytes,
    DownloadStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadTask(
      seriesId: seriesId,
      seriesTitle: seriesTitle,
      totalChapters: totalChapters ?? this.totalChapters,
      downloadedChapters: downloadedChapters ?? this.downloadedChapters,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      startedAt: startedAt,
    );
  }
}
