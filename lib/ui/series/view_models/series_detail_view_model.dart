import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/series_repository.dart';
import '../../../domain/models/series.dart';
import 'series_list_view_model.dart';

/// RIVERPOD PROVIDER: Đăng ký ViewModel cho màn hình chi tiết truyện
/// Sử dụng AsyncNotifierProvider.family để truyền mã [seriesId]
final seriesDetailViewModelProvider =
    AsyncNotifierProvider.family<SeriesDetailViewModel, Series, String>(
  SeriesDetailViewModel.new,
  retry: (retryCount, error) => null,
);

/// VIEWMODEL - Quản lý trạng thái và nghiệp vụ màn hình Chi tiết truyện (SeriesDetailScreen)
/// Áp dụng các nguyên tắc kiến trúc:
/// 1. Tận dụng bộ đệm (cache) từ SeriesListViewModel để hiển thị giao diện tức thì không giật lag.
/// 2. Bắt lỗi an toàn và bọc trong AsyncValue để UI hiển thị đủ 4 trạng thái chuẩn.
/// 3. Optimistic UI với Rollback cho tính năng Bookmark (Lưu vào tủ sách).
/// 4. Đồng bộ 2 chiều với danh sách truyện ở trang chủ.
class SeriesDetailViewModel extends AsyncNotifier<Series> {
  final String seriesId;

  SeriesDetailViewModel(this.seriesId);

  @override
  Future<Series> build() async {
    // 1. Đọc bộ nhớ cache từ danh sách truyện nếu đã tải trước đó
    final list = ref.read(seriesListViewModelProvider).value;
    final cached = list?.where((s) => s.id == seriesId).firstOrNull;
    if (cached != null) {
      return cached;
    }

    // 2. Nếu chưa có trong cache, gọi Repository tải từ Gateway
    return ref.watch(seriesRepositoryProvider).getSeriesById(seriesId);
  }

  /// Kéo để làm mới dữ liệu chi tiết truyện (Pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(seriesRepositoryProvider).getSeriesById(seriesId),
    );
  }

  /// Bật/Tắt Lưu vào Tủ sách (Optimistic UI kèm Rollback khi lỗi)
  /// Trả về true nếu thành công, false nếu lỗi để UI hiển thị SnackBar
  Future<bool> toggleBookmark() async {
    final current = state.value;
    if (current == null) return false;

    final original = current;
    final newBookmarkState = !current.isBookmarked;

    // BƯỚC 1: Cập nhật Lạc quan (Optimistic Update) trên giao diện chi tiết
    state = AsyncData(current.copyWith(isBookmarked: newBookmarkState));

    // BƯỚC 2: Đồng bộ trạng thái mới sang danh sách truyện ngoài trang chủ (nếu có)
    ref
        .read(seriesListViewModelProvider.notifier)
        .updateBookmarkLocally(seriesId, newBookmarkState);

    // BƯỚC 3: Gửi request ngầm lên API Gateway
    try {
      await ref
          .read(seriesRepositoryProvider)
          .toggleBookmark(seriesId, newBookmarkState);
      return true;
    } catch (_) {
      // BƯỚC 4: Rollback phục hồi lại trạng thái cũ nếu gặp sự cố mạng
      state = AsyncData(original);
      ref
          .read(seriesListViewModelProvider.notifier)
          .updateBookmarkLocally(seriesId, original.isBookmarked);
      return false;
    }
  }
}
