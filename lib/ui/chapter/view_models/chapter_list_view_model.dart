import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/chapter_repository.dart';
import '../../../data/repositories/offline_series_repository.dart';
import '../../../data/repositories/series_repository.dart';
import '../../../data/services/reading_preferences_service.dart';
import '../../../domain/models/chapter.dart';
import '../../../domain/models/reading_progress.dart';
import '../../auth/view_models/auth_session_view_model.dart';

/// RIVERPOD PROVIDER: Đăng ký ViewModel cho màn hình danh sách chương
/// Riverpod 3 Family Provider truyền [seriesId] trực tiếp vào constructor của ViewModel.
final chapterListViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<ChapterListViewModel, List<Chapter>, String>(
      ChapterListViewModel.new,
      retry: (retryCount, error) => null,
    );

/// RIVERPOD PROVIDER: Đọc danh sách chương trực tiếp từ SQLite (chế độ đọc Offline)
final offlineChapterListProvider = FutureProvider.autoDispose
    .family<List<Chapter>, String>((ref, seriesId) {
      return ref
          .watch(offlineSeriesRepositoryProvider)
          .getDownloadedChapters(seriesId);
    });

/// VIEWMODEL - Quản lý trạng thái tải danh sách chương
/// Tiến độ đọc lấy từ Library API là nguồn chính; bản lưu cục bộ chỉ dùng
/// khi chưa đăng nhập hoặc không gọi được server.
class ChapterListViewModel extends AsyncNotifier<List<Chapter>> {
  final String seriesId;

  ChapterListViewModel(this.seriesId);

  @override
  Future<List<Chapter>> build() {
    // Tự refresh khi đăng nhập / đăng xuất / đổi tài khoản để lấy đúng tiến độ.
    ref.listen(authSessionProvider, (previous, next) {
      if (previous?.value?.userId != next.value?.userId) {
        refresh();
      }
    });
    return _load();
  }

  /// Kéo để làm mới danh sách chương (Pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(_load);
    if (ref.mounted) {
      state = result;
    }
  }

  Future<List<Chapter>> _load() async {
    final chapters = await ref
        .read(chapterRepositoryProvider)
        .getChaptersBySeries(seriesId);
    if (!ref.mounted) return chapters;

    final session = ref.read(authSessionProvider).value;
    if (session != null) {
      try {
        final progress = await ref
            .read(seriesRepositoryProvider)
            .getReadingProgressDetail(seriesId);
        if (!ref.mounted) return chapters;
        if (progress == null) {
          // Server xác nhận tài khoản chưa đọc bộ truyện này -> không dùng
          // bản local cũ để tránh lẫn tiến độ của tài khoản khác trên máy.
          return chapters;
        }
        return _applyProgress(chapters, progress);
      } catch (_) {
        // Lỗi mạng: tạm dùng tiến độ lưu cục bộ.
      }
    }

    if (!ref.mounted) return chapters;

    final local = await ref
        .read(readingPreferencesServiceProvider)
        .getLastReadProgress(seriesId);
    if (local == null) return chapters;
    return _apply(
      chapters,
      chapterId: local.chapterId,
      sortOrder: local.sortOrder,
      readPercentage: local.readPercentage,
    );
  }

  /// Cập nhật tiến độ ngay trên danh sách đang hiển thị khi trình đọc ghi nhận
  /// chương mới, không cần chờ gọi lại API.
  void updateProgressLocally({
    required String chapterId,
    required int sortOrder,
    required double progress,
    required bool isCompleted,
  }) {
    final chapters = state.value;
    if (chapters == null) return;
    final updated = _apply(
      chapters,
      chapterId: chapterId,
      sortOrder: sortOrder,
      readPercentage: progress,
      markActiveCompleted: isCompleted,
    );
    if (!identical(updated, chapters)) {
      state = AsyncData(updated);
    }
  }

  List<Chapter> _applyProgress(
    List<Chapter> chapters,
    ReadingProgress progress,
  ) {
    return _apply(
      chapters,
      chapterId: progress.chapterId,
      sortOrder: progress.chapterSortOrder,
      readPercentage: progress.progress,
      markActiveCompleted: progress.isCompleted,
    );
  }

  List<Chapter> _apply(
    List<Chapter> chapters, {
    String? chapterId,
    int? sortOrder,
    required double readPercentage,
    bool markActiveCompleted = false,
  }) {
    var activeIndex = -1;
    if (chapterId != null && chapterId.isNotEmpty) {
      activeIndex = chapters.indexWhere((chapter) => chapter.id == chapterId);
    }
    if (activeIndex < 0 && sortOrder != null) {
      activeIndex = chapters.indexWhere(
        (chapter) => chapter.sortOrder == sortOrder,
      );
    }
    if (activeIndex < 0) return chapters;

    final activeChapter = chapters[activeIndex];
    final clampedProgress = readPercentage.clamp(0.0, 1.0);

    return chapters
        .map((chapter) {
          final isActive = chapter.id == activeChapter.id;
          return chapter.copyWith(
            isActive: isActive,
            readPercentage: isActive
                ? clampedProgress
                : (chapter.sortOrder < activeChapter.sortOrder ? 1.0 : 0.0),
            isCompleted:
                chapter.sortOrder < activeChapter.sortOrder ||
                (isActive && markActiveCompleted),
          );
        })
        .toList(growable: false);
  }
}
