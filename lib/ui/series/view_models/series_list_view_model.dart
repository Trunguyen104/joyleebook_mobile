import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/series_repository.dart';
import '../../../domain/models/series.dart';
import '../../bookmark/view_models/bookmark_list_view_model.dart';
import '../../bookmark/view_models/bookmark_status_view_model.dart';

/// RIVERPOD PROVIDER: Đăng ký ViewModel cho toàn bộ màn hình danh sách truyện & tra cứu
final seriesListViewModelProvider =
    AsyncNotifierProvider<SeriesListViewModel, List<Series>>(
  SeriesListViewModel.new,
  retry: (retryCount, error) => null,
);

/// VIEWMODEL - Quản lý trạng thái và nghiệp vụ màn hình Khám phá & Tra cứu truyện
/// Bước 4 trong kiến trúc Compass App:
/// Kế thừa `AsyncNotifier<List<Series>>` để quản lý trạng thái tải danh sách truyện.
///
/// 4 NGUYÊN TẮC CỐT LÕI:
/// 1. Bộ 4 trạng thái: Loading, Data, Empty, Error.
/// 2. Debounce tìm kiếm: Người dùng gõ phím liên tục sẽ không gọi API ngay, chờ 400ms mới gọi.
/// 3. Lọc đa tiêu chí: Tìm kiếm từ khóa + Thể loại (Genre) + Trạng thái (Status).
/// 4. Optimistic UI: Khi người dùng bấm lưu truyện, cập nhật giao diện TRƯỚC để tạo cảm giác tức thì; nếu mạng lỗi thì Rollback SAU.
class SeriesListViewModel extends AsyncNotifier<List<Series>> {
  Timer? _debounceTimer;
  final Set<String> _bookmarkRequestsInFlight = {};

  String _currentQuery = '';
  String? _selectedGenre;
  SeriesStatus? _selectedStatus;

  String get currentQuery => _currentQuery;
  String? get selectedGenre => _selectedGenre;
  SeriesStatus? get selectedStatus => _selectedStatus;
  bool get isFiltered =>
      _currentQuery.isNotEmpty ||
      _selectedGenre != null ||
      _selectedStatus != null;

  @override
  Future<List<Series>> build() {
    return _fetch();
  }

  Future<List<Series>> _fetch() {
    return ref.read(seriesRepositoryProvider).getSeriesList(
          searchQuery: _currentQuery.isNotEmpty ? _currentQuery : null,
          genre: _selectedGenre,
          status: _selectedStatus,
        );
  }

  /// 1. Kéo xuống để làm mới danh sách (Pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// 2. Tìm kiếm truyện theo từ khóa (Có cơ chế Debounce 400ms)
  void search(String query) {
    _debounceTimer?.cancel();
    _currentQuery = query.trim();

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(_fetch);
    });
  }

  /// 3. Lọc theo thể loại
  /// Nếu chọn lại thể loại đang active -> hủy lọc (chọn 'Tất cả')
  Future<void> filterByGenre(String? genre) async {
    _debounceTimer?.cancel();
    if (_selectedGenre == genre) {
      _selectedGenre = null;
    } else {
      _selectedGenre = genre;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// 4. Lọc theo trạng thái truyện (Hoàn thành / Đang ra)
  Future<void> filterByStatus(SeriesStatus? status) async {
    _debounceTimer?.cancel();
    if (_selectedStatus == status) {
      _selectedStatus = null;
    } else {
      _selectedStatus = status;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// 5. Xóa toàn bộ bộ lọc và từ khóa tìm kiếm
  Future<void> clearFilters() async {
    _debounceTimer?.cancel();
    _currentQuery = '';
    _selectedGenre = null;
    _selectedStatus = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// 6. Bật/Tắt Lưu vào Tủ sách (Optimistic UI kèm Rollback khi lỗi)
  Future<bool> toggleBookmark(String seriesId) async {
    if (_bookmarkRequestsInFlight.contains(seriesId)) return false;

    final currentList = state.value;
    if (currentList == null) return false;

    final targetIndex = currentList.indexWhere((s) => s.id == seriesId);
    if (targetIndex == -1) return false;

    final originalItem = currentList[targetIndex];
    final currentStatus = ref.read(bookmarkStatusViewModelProvider)[seriesId] ??
        originalItem.isBookmarked;
    final newBookmarkState = !currentStatus;
    _bookmarkRequestsInFlight.add(seriesId);

    // BƯỚC A: Cập nhật Lạc quan (Optimistic Update)
    // Đổi trạng thái icon trên UI ngay lập tức để người dùng thấy phản hồi tức thì
    final itemWithNewState = originalItem.copyWith(
      isBookmarked: newBookmarkState,
    );
    final updatedList = List<Series>.from(currentList);
    updatedList[targetIndex] = itemWithNewState;
    state = AsyncData(updatedList);
    ref
        .read(bookmarkStatusViewModelProvider.notifier)
        .setStatus(seriesId, newBookmarkState);
    ref
        .read(bookmarkListViewModelProvider.notifier)
        .updateBookmarkLocally(itemWithNewState, newBookmarkState);

    // BƯỚC B: Gửi request ngầm lên server
    try {
      await ref
          .read(seriesRepositoryProvider)
          .toggleBookmark(seriesId, newBookmarkState);
      return true;
    } catch (_) {
      // BƯỚC C: Phục hồi lại (Rollback) nếu mạng lỗi hoặc server từ chối
      final rollbackList = List<Series>.from(state.value ?? currentList);
      rollbackList[targetIndex] = originalItem.copyWith(
        isBookmarked: currentStatus,
      );
      state = AsyncData(rollbackList);
      ref
          .read(bookmarkStatusViewModelProvider.notifier)
          .setStatus(seriesId, currentStatus);
      ref
          .read(bookmarkListViewModelProvider.notifier)
          .updateBookmarkLocally(originalItem, currentStatus);
      return false; // Báo về cho UI hiển thị SnackBar cảnh báo
    } finally {
      _bookmarkRequestsInFlight.remove(seriesId);
    }
  }

  /// 7. Đồng bộ trạng thái Bookmark từ màn hình chi tiết
  void updateBookmarkLocally(String seriesId, bool isBookmarked) {
    final currentList = state.value;
    if (currentList == null) return;

    final targetIndex = currentList.indexWhere((s) => s.id == seriesId);
    if (targetIndex == -1) return;

    final updatedList = List<Series>.from(currentList);
    updatedList[targetIndex] = updatedList[targetIndex].copyWith(
      isBookmarked: isBookmarked,
    );
    state = AsyncData(updatedList);
  }

  /// 8. Đồng bộ trạng thái Đánh giá từ màn hình chi tiết sang danh sách ngoài
  void updateRatingLocally({
    required String seriesId,
    required double averageRating,
    required int totalRatings,
    int? userRating,
  }) {
    final currentList = state.value;
    if (currentList == null) return;

    final targetIndex = currentList.indexWhere((s) => s.id == seriesId);
    if (targetIndex == -1) return;

    final updatedList = List<Series>.from(currentList);
    updatedList[targetIndex] = updatedList[targetIndex].copyWith(
      averageRating: averageRating,
      totalRatings: totalRatings,
      userRating: userRating,
    );
    state = AsyncData(updatedList);
  }
}
