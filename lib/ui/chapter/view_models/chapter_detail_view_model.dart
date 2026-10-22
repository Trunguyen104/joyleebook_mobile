import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/chapter_repository.dart';
import '../../../domain/models/chapter_detail.dart';

/// RIVERPOD PROVIDER: Đăng ký ViewModel cho màn hình đọc nội dung chương
final chapterDetailViewModelProvider = AsyncNotifierProvider.family<
    ChapterDetailViewModel, ChapterDetail, String>(
  ChapterDetailViewModel.new,
  retry: (retryCount, error) => null,
);

/// VIEWMODEL - Quản lý tải và hiển thị nội dung chương
class ChapterDetailViewModel extends AsyncNotifier<ChapterDetail> {
  final String chapterId;

  ChapterDetailViewModel(this.chapterId);

  @override
  Future<ChapterDetail> build() {
    return ref.watch(chapterRepositoryProvider).getChapterDetail(chapterId);
  }

  /// Làm mới nội dung chương
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chapterRepositoryProvider).getChapterDetail(chapterId),
    );
  }
}
