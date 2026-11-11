import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/offline_series_repository.dart';
import '../../../domain/models/downloaded_series.dart';

/// RIVERPOD PROVIDER: Quản lý danh sách các tác phẩm đã tải về máy
final downloadedSeriesViewModelProvider =
    AsyncNotifierProvider<DownloadedSeriesViewModel, List<DownloadedSeries>>(
      DownloadedSeriesViewModel.new,
    );

/// RIVERPOD PROVIDER: Lấy thông tin bản tải của một tác phẩm theo [seriesId] (null nếu chưa tải)
final downloadedSeriesByIdProvider = Provider.family<DownloadedSeries?, String>(
  (ref, seriesId) {
    final list = ref.watch(downloadedSeriesViewModelProvider).value ?? [];
    for (final item in list) {
      if (item.id == seriesId) return item;
    }
    return null;
  },
);

/// VIEWMODEL - Quản lý danh sách truyện đọc offline, bộ nhớ lưu trữ và thao tác xóa
class DownloadedSeriesViewModel extends AsyncNotifier<List<DownloadedSeries>> {
  @override
  Future<List<DownloadedSeries>> build() {
    final repo = ref.watch(offlineSeriesRepositoryProvider);
    return repo.getDownloadedSeriesList();
  }

  /// Làm mới danh sách truyện offline từ SQLite
  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(offlineSeriesRepositoryProvider).getDownloadedSeriesList(),
    );
  }

  /// Xóa bản tải của một bộ truyện (Optimistic UI: cập nhật state ngay lập tức, rollback nếu lỗi)
  Future<void> deleteSeries(String seriesId) async {
    final previousList = state.value ?? [];
    // Cập nhật lạc quan trên UI
    state = AsyncData(previousList.where((s) => s.id != seriesId).toList());

    try {
      await ref
          .read(offlineSeriesRepositoryProvider)
          .deleteDownloadedSeries(seriesId);
    } catch (e, st) {
      // Hoàn tác về danh sách cũ nếu xóa thất bại
      state = AsyncData(previousList);
      state = AsyncError(e, st);
    }
  }

  /// Xóa toàn bộ truyện offline trong thiết bị
  Future<void> deleteAll() async {
    final previousList = state.value ?? [];
    state = const AsyncData([]);

    try {
      await ref.read(offlineSeriesRepositoryProvider).deleteAllDownloads();
    } catch (e, st) {
      state = AsyncData(previousList);
      state = AsyncError(e, st);
    }
  }

  /// Tính tổng dung lượng (bytes) của các bộ truyện đã tải
  int get totalBytes {
    final list = state.value ?? [];
    return list.fold<int>(0, (sum, item) => sum + item.totalBytes);
  }

  /// Định dạng tổng dung lượng sang chuỗi thân thiện (ví dụ: "12.4 MB")
  String get formattedTotalBytes {
    final bytes = totalBytes;
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
