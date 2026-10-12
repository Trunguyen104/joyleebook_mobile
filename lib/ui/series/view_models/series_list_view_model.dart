import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/series_repository.dart';
import '../../../domain/models/series.dart';

/// RIVERPOD PROVIDER: Đăng ký ViewModel cho toàn bộ màn hình danh sách truyện
/// AsyncNotifierProvider tự động quản lý vòng đời và trạng thái bất đồng bộ (AsyncValue)
final seriesListViewModelProvider =
    AsyncNotifierProvider<SeriesListViewModel, List<Series>>(
  SeriesListViewModel.new,
);

/// VIEWMODEL - Quản lý trạng thái và nghiệp vụ màn hình
/// Bước 4 trong kiến trúc Compass App:
/// Kế thừa `AsyncNotifier<List<Series>>` để quản lý trạng thái tải danh sách truyện.
/// 
/// 3 NGUYÊN TẮC CỐT LÕI CHO NGƯỜI MỚI HỌC:
/// 1. Tự động hóa 3 trạng thái: AsyncLoading (đang tải), AsyncData (có dữ liệu), AsyncError (lỗi).
/// 2. Debounce tìm kiếm: Người dùng gõ chữ liên tục sẽ không gọi API ngay, chờ 400ms mới gọi để đỡ tốn tài nguyên.
/// 3. Optimistic UI: Khi người dùng bấm lưu truyện, cập nhật giao diện TRƯỚC để tạo cảm giác tức thì; nếu mạng lỗi thì Rollback (khôi phục lại) SAU.
class SeriesListViewModel extends AsyncNotifier<List<Series>> {
  // Bộ đếm thời gian dùng cho tính năng tìm kiếm (Debounce)
  Timer? _debounceTimer;

  /// Hàm build() được Riverpod tự động gọi đầu tiên khi màn hình mở lên
  @override
  Future<List<Series>> build() {
    // Đọc repository và tải danh sách truyện ban đầu
    return ref.watch(seriesRepositoryProvider).getSeriesList();
  }

  /// 1. Kéo xuống để làm mới danh sách (Pull-to-refresh)
  Future<void> refresh() async {
    // Đặt trạng thái về Loading để UI hiển thị vòng quay nếu cần
    state = const AsyncLoading();

    // AsyncValue.guard: Tự động bắt lỗi nếu có và chuyển thành AsyncError an toàn
    state = await AsyncValue.guard(
      () => ref.read(seriesRepositoryProvider).getSeriesList(),
    );
  }

  /// 2. Tìm kiếm truyện theo từ khóa (Có cơ chế Debounce 400ms)
  void search(String query) {
    // Hủy bộ đếm trước đó nếu người dùng vẫn đang gõ phím
    _debounceTimer?.cancel();

    // Khởi tạo bộ đếm mới: Chờ 400ms sau khi người dùng ngừng gõ
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(
        () => ref.read(seriesRepositoryProvider).getSeriesList(searchQuery: query),
      );
    });
  }

  /// 3. Bật/Tắt Lưu vào Tủ sách (Optimistic UI kèm Rollback khi lỗi)
  /// Trả về true nếu thành công, false nếu thất bại để UI hiển thị SnackBar thông báo
  Future<bool> toggleBookmark(String seriesId) async {
    // Lấy danh sách truyện hiện tại trong State
    final currentList = state.value;
    if (currentList == null) return false;

    // Tìm vị trí của truyện cần cập nhật
    final targetIndex = currentList.indexWhere((s) => s.id == seriesId);
    if (targetIndex == -1) return false;

    final originalItem = currentList[targetIndex];
    final newBookmarkState = !originalItem.isBookmarked;

    // BƯỚC A: Cập nhật Lạc quan (Optimistic Update)
    // Đổi trạng thái icon trên UI ngay lập tức để người dùng thấy phản hồi tức thì
    final updatedList = List<Series>.from(currentList);
    updatedList[targetIndex] = originalItem.copyWith(isBookmarked: newBookmarkState);
    state = AsyncData(updatedList);

    // BƯỚC B: Gửi request ngầm lên server
    try {
      await ref
          .read(seriesRepositoryProvider)
          .toggleBookmark(seriesId, newBookmarkState);
      return true; // Lưu thành công
    } catch (_) {
      // BƯỚC C: Phục hồi lại (Rollback) nếu mạng lỗi hoặc server từ chối
      final rollbackList = List<Series>.from(state.value ?? currentList);
      rollbackList[targetIndex] = originalItem;
      state = AsyncData(rollbackList);
      return false; // Báo về cho UI hiển thị SnackBar cảnh báo
    }
  }
}
