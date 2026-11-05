import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/series_repository.dart';
import '../../../domain/models/series.dart';
import '../../auth/view_models/auth_session_view_model.dart';
import '../../bookmark/view_models/bookmark_list_view_model.dart';
import '../../bookmark/view_models/bookmark_status_view_model.dart';
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
/// 3. Optimistic UI với Rollback cho tính năng Bookmark (Lưu vào tủ sách) và Rating (Đánh giá).
/// 4. Đồng bộ 2 chiều với danh sách truyện ở trang chủ.
class SeriesDetailViewModel extends AsyncNotifier<Series> {
  final String seriesId;

  SeriesDetailViewModel(this.seriesId);

  @override
  Future<Series> build() async {
    // 1. Lắng nghe khi phiên đăng nhập thay đổi (đăng nhập / đăng xuất / đổi tài khoản)
    // để tự động cập nhật my-rating và điểm số mới nhất mà không block build ban đầu
    ref.listen(authSessionProvider, (previous, next) {
      if (previous?.value?.userId != next.value?.userId) {
        refresh();
      }
    });

    // 2. Lắng nghe trạng thái bookmark thay đổi từ màn hình khác
    ref.listen(bookmarkStatusViewModelProvider, (previous, next) {
      final status = next[seriesId];
      final current = state.value;
      if (status != null && current != null && current.isBookmarked != status) {
        state = AsyncData(current.copyWith(isBookmarked: status));
      }
    });

    return _loadSeries();
  }

  /// Kéo để làm mới dữ liệu chi tiết truyện (Pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadSeries);
  }

  Future<Series> _loadSeries() async {
    // Luôn tải trực tiếp từ Repository để đảm bảo đồng bộ điểm đánh giá (userRating) của tài khoản hiện tại
    final series =
        await ref.read(seriesRepositoryProvider).getSeriesById(seriesId);
    bool isBookmarked = series.isBookmarked;
    try {
      isBookmarked = await ref
          .read(seriesRepositoryProvider)
          .getBookmarkStatus(seriesId);
    } catch (_) {
      // Giữ nguyên trạng thái bookmark nếu chưa đăng nhập hoặc gặp lỗi mạng
      isBookmarked = ref.read(bookmarkStatusViewModelProvider)[seriesId] ??
          series.isBookmarked;
    }
    final updated = series.copyWith(isBookmarked: isBookmarked);
    _syncBookmarkStatus(updated, isBookmarked);
    return updated;
  }

  void _syncBookmarkStatus(Series series, bool isBookmarked) {
    ref
        .read(bookmarkStatusViewModelProvider.notifier)
        .setStatus(seriesId, isBookmarked);
    ref
        .read(seriesListViewModelProvider.notifier)
        .updateBookmarkLocally(seriesId, isBookmarked);
    ref
        .read(bookmarkListViewModelProvider.notifier)
        .updateBookmarkLocally(series, isBookmarked);
  }

  /// Bật/Tắt Lưu vào Tủ sách (Optimistic UI kèm Rollback khi lỗi)
  /// Trả về true nếu thành công, false nếu lỗi để UI hiển thị SnackBar
  Future<bool> toggleBookmark() async {
    final current = state.value;
    if (current == null) return false;

    final original = current;
    final currentStatus = ref.read(bookmarkStatusViewModelProvider)[seriesId] ??
        current.isBookmarked;
    final newBookmarkState = !currentStatus;

    final updated = current.copyWith(isBookmarked: newBookmarkState);

    // BƯỚC 1: Cập nhật Lạc quan (Optimistic Update) trên giao diện chi tiết
    state = AsyncData(updated);

    // BƯỚC 2: Đồng bộ trạng thái mới sang danh sách truyện ngoài trang chủ (nếu có)
    ref
        .read(seriesListViewModelProvider.notifier)
        .updateBookmarkLocally(seriesId, newBookmarkState);
    _syncBookmarkStatus(updated, newBookmarkState);

    // BƯỚC 3: Gửi request ngầm lên API Gateway
    try {
      await ref
          .read(seriesRepositoryProvider)
          .toggleBookmark(seriesId, newBookmarkState);
      return true;
    } catch (_) {
      // BƯỚC 4: Rollback phục hồi lại trạng thái cũ nếu gặp sự cố mạng
      state = AsyncData(original.copyWith(isBookmarked: currentStatus));
      _syncBookmarkStatus(original, currentStatus);
      return false;
    }
  }

  /// Đánh giá hoặc Cập nhật đánh giá tác phẩm (Optimistic UI kèm Rollback)
  /// Điểm đánh giá bắt buộc thuộc thang 1 - 5 sao.
  /// Trả về true nếu thành công, false nếu có lỗi xảy ra.
  Future<bool> rateSeries(int score) async {
    // 1. Kiểm tra validation ranh giới (Boundary check): 1 <= score <= 5
    if (score < 1 || score > 5) {
      return false;
    }

    final current = state.value;
    if (current == null) return false;

    final original = current;
    final isFirstRate = current.userRating == null;
    final newTotal = isFirstRate ? current.totalRatings + 1 : current.totalRatings;
    final currentSum = current.averageRating * current.totalRatings;
    final newSum = isFirstRate
        ? (currentSum + score)
        : (currentSum - (current.userRating ?? 0) + score);
    final newAvg = newTotal > 0 ? (newSum / newTotal) : score.toDouble();
    final roundedAvg = double.parse(newAvg.toStringAsFixed(1));

    // BƯỚC 1: Cập nhật Lạc quan (Optimistic Update)
    state = AsyncData(current.copyWith(
      userRating: score,
      totalRatings: newTotal,
      averageRating: roundedAvg,
    ));

    // Đồng bộ sang danh sách ngoài trang chủ
    ref.read(seriesListViewModelProvider.notifier).updateRatingLocally(
      seriesId: seriesId,
      averageRating: roundedAvg,
      totalRatings: newTotal,
      userRating: score,
    );

    // BƯỚC 2: Gửi request lên Gateway
    try {
      await ref
          .read(seriesRepositoryProvider)
          .rateSeries(seriesId, score);

      // Đồng bộ lại dữ liệu chuẩn xác nhất từ server
      final fresh = await ref
          .read(seriesRepositoryProvider)
          .getSeriesById(seriesId);
      state = AsyncData(fresh.copyWith(isBookmarked: current.isBookmarked));
      ref.read(seriesListViewModelProvider.notifier).updateRatingLocally(
        seriesId: seriesId,
        averageRating: fresh.averageRating,
        totalRatings: fresh.totalRatings,
        userRating: fresh.userRating,
      );
      return true;
    } catch (_) {
      // BƯỚC 3: Rollback khi lỗi
      state = AsyncData(original);
      ref.read(seriesListViewModelProvider.notifier).updateRatingLocally(
        seriesId: seriesId,
        averageRating: original.averageRating,
        totalRatings: original.totalRatings,
        userRating: original.userRating,
        clearUserRating: original.userRating == null,
      );
      return false;
    }
  }
}
