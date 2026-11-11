import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/chapter_repository.dart';
import '../../../data/repositories/offline_chapter_repository.dart';
import '../../../data/services/api_exceptions.dart';
import '../../../ui/auth/view_models/auth_session_view_model.dart';
import '../../../domain/models/chapter_detail.dart';

/// RIVERPOD PROVIDER: Đăng ký ViewModel cho màn hình đọc nội dung chương
final chapterDetailViewModelProvider =
    AsyncNotifierProvider.family<ChapterDetailViewModel, ChapterDetail, String>(
      ChapterDetailViewModel.new,
      retry: (retryCount, error) => null,
    );

/// VIEWMODEL - Quản lý tải và hiển thị nội dung chương
class ChapterDetailViewModel extends AsyncNotifier<ChapterDetail> {
  final String chapterId;

  ChapterDetailViewModel(this.chapterId);

  @override
  Future<ChapterDetail> build() => _load();

  Future<ChapterDetail> _load() async {
    try {
      return await ref
          .read(chapterRepositoryProvider)
          .getChapterDetail(chapterId);
    } catch (error) {
      final session = ref.read(authSessionProvider).value;
      if (session != null) {
        try {
          final offline = await ref
              .read(offlineChapterRepositoryProvider)
              .get(session.userId, chapterId);
          if (offline != null) {
            return ChapterDetail(
              id: offline.id,
              seriesId: offline.seriesId,
              title: offline.title,
              content: offline.content,
              sortOrder: offline.sortOrder,
              totalChapters: offline.totalChapters,
              status: offline.status,
              publishedAt: offline.publishedAt,
            );
          }
        } catch (_) {
          // Không có SQLite thì giữ lỗi mạng gốc để UI cho phép thử lại.
        }
      }
      if (error is AppException) rethrow;
      rethrow;
    }
  }

  /// Làm mới nội dung chương
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}
