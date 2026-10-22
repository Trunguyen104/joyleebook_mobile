import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/chapter_repository.dart';
import '../../../domain/models/chapter.dart';

/// RIVERPOD PROVIDER: Đăng ký ViewModel cho màn hình danh sách chương
/// Riverpod 3 Family Provider truyền [seriesId] trực tiếp vào constructor của ViewModel.
final chapterListViewModelProvider = AsyncNotifierProvider.family<
    ChapterListViewModel, List<Chapter>, String>(
  ChapterListViewModel.new,
);

/// VIEWMODEL - Quản lý trạng thái tải danh sách chương
class ChapterListViewModel extends AsyncNotifier<List<Chapter>> {
  final String seriesId;

  ChapterListViewModel(this.seriesId);

  @override
  Future<List<Chapter>> build() {
    // Tự động gọi Repository để tải danh sách chương theo seriesId
    return ref.watch(chapterRepositoryProvider).getChaptersBySeries(seriesId);
  }

  /// Kéo để làm mới danh sách chương (Pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chapterRepositoryProvider).getChaptersBySeries(seriesId),
    );
  }
}
