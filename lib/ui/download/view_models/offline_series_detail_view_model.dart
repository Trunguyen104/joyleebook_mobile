import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/offline_series_repository.dart';
import '../../../data/services/reading_preferences_service.dart';
import '../../../domain/models/chapter.dart';
import '../../../domain/models/downloaded_series.dart';

/// Trạng thái dữ liệu chi tiết tác phẩm ngoại tuyến
@immutable
class OfflineSeriesDetailState {
  final DownloadedSeries? series;
  final List<Chapter> chapters;

  const OfflineSeriesDetailState({this.series, this.chapters = const []});
}

/// RIVERPOD PROVIDER: Quản lý chi tiết tác phẩm và danh sách chương đã tải theo [seriesId]
final offlineSeriesDetailViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<OfflineSeriesDetailViewModel, OfflineSeriesDetailState, String>(
      OfflineSeriesDetailViewModel.new,
    );

/// VIEWMODEL - Nạp thông tin truyện & danh sách chương từ SQLite kèm tiến độ đọc offline
class OfflineSeriesDetailViewModel
    extends AsyncNotifier<OfflineSeriesDetailState> {
  final String seriesId;

  OfflineSeriesDetailViewModel(this.seriesId);

  @override
  Future<OfflineSeriesDetailState> build() {
    return _load();
  }

  Future<OfflineSeriesDetailState> _load() async {
    final offlineRepo = ref.watch(offlineSeriesRepositoryProvider);
    final series = await offlineRepo.getDownloadedSeries(seriesId);
    if (series == null) {
      return const OfflineSeriesDetailState(series: null, chapters: []);
    }

    var chapters = await offlineRepo.getDownloadedChapters(seriesId);

    // Áp dụng tiến độ đọc cục bộ gần nhất (ưu tiên bản mới nhất giữa SQLite và SharedPreferences)
    LocalReadingProgress? progress = await offlineRepo.getOfflineProgress(
      seriesId,
    );
    final prefProgress = await ref
        .read(readingPreferencesServiceProvider)
        .getLastReadProgress(seriesId);
    if (prefProgress != null &&
        (progress == null ||
            prefProgress.updatedAt.isAfter(progress.updatedAt))) {
      progress = prefProgress;
    }

    if (progress != null && chapters.isNotEmpty) {
      chapters = _applyProgress(chapters, progress);
    }

    return OfflineSeriesDetailState(series: series, chapters: chapters);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  List<Chapter> _applyProgress(
    List<Chapter> chapters,
    LocalReadingProgress progress,
  ) {
    final activeSort = progress.sortOrder;
    return chapters
        .map((c) {
          final isMatch =
              c.id == progress.chapterId || c.sortOrder == activeSort;
          if (isMatch) {
            return c.copyWith(
              isActive: true,
              readPercentage: progress.readPercentage,
              isCompleted: progress.readPercentage >= 0.99,
            );
          }
          if (c.sortOrder < activeSort) {
            return c.copyWith(isCompleted: true, readPercentage: 1.0);
          }
          return c;
        })
        .toList(growable: false);
  }
}
