import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/series_download_manager.dart';
import '../../../domain/models/download_task.dart';
import '../../../domain/models/series.dart';
import 'downloaded_series_view_model.dart';

/// RIVERPOD PROVIDER: Quản lý các task tải truyện đang diễn ra trong ứng dụng
final downloadManagerViewModelProvider =
    NotifierProvider<DownloadManagerViewModel, Map<String, DownloadTask>>(
      DownloadManagerViewModel.new,
    );

/// VIEWMODEL - Điều phối và cập nhật trạng thái các tác vụ download theo thời gian thực
class DownloadManagerViewModel extends Notifier<Map<String, DownloadTask>> {
  StreamSubscription<DownloadTask>? _sub;

  @override
  Map<String, DownloadTask> build() {
    final manager = ref.watch(seriesDownloadManagerProvider);

    _sub?.cancel();
    _sub = manager.onTaskUpdated.listen((task) {
      state = {...state, task.seriesId: task};

      // Khi một task hoàn tất, tự động refresh danh sách truyện đã tải
      if (task.status == DownloadStatus.completed) {
        ref.invalidate(downloadedSeriesViewModelProvider);
      }
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    return manager.allTasks;
  }

  /// Bắt đầu tải toàn bộ một tác phẩm
  Future<void> startDownload(Series series) async {
    final manager = ref.read(seriesDownloadManagerProvider);
    await manager.startDownload(series);
  }

  /// Tạm dừng hoặc hủy tải
  void cancelDownload(String seriesId) {
    ref.read(seriesDownloadManagerProvider).cancelDownload(seriesId);
  }

  /// Lấy task của một bộ truyện
  DownloadTask? getTask(String seriesId) {
    return state[seriesId] ??
        ref.read(seriesDownloadManagerProvider).getTask(seriesId);
  }

  /// Kiểm tra xem truyện có đang được tải ngầm hay không
  bool isDownloading(String seriesId) {
    final task = getTask(seriesId);
    return task != null && task.status.isActive;
  }
}
