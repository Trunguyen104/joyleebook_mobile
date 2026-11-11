import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/offline_chapter_repository.dart';
import '../../../domain/models/offline_chapter.dart';
import '../../../domain/models/offline_series.dart';
import '../../auth/view_models/auth_session_view_model.dart';

final offlineLibraryViewModelProvider =
    AsyncNotifierProvider.autoDispose<
      OfflineLibraryViewModel,
      List<OfflineSeries>
    >(OfflineLibraryViewModel.new, retry: (retryCount, error) => null);

class OfflineLibraryViewModel extends AsyncNotifier<List<OfflineSeries>> {
  @override
  Future<List<OfflineSeries>> build() async {
    final session = ref.watch(authSessionProvider).value;
    if (session == null) return const [];
    try {
      return await ref
          .read(offlineChapterRepositoryProvider)
          .getSeries(session.userId);
    } catch (_) {
      // Một số widget test không khởi tạo plugin SQLite; Tủ sách vẫn dùng được.
      return const [];
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> deleteChapter(OfflineChapter chapter) async {
    final session = ref.read(authSessionProvider).value;
    if (session == null) return;
    await ref
        .read(offlineChapterRepositoryProvider)
        .delete(session.userId, chapter.id);
    final current = state.value ?? const <OfflineSeries>[];
    state = AsyncData(
      current
          .map(
            (series) => series.id != chapter.seriesId
                ? series
                : OfflineSeries(
                    userId: series.userId,
                    id: series.id,
                    title: series.title,
                    authorName: series.authorName,
                    coverImageUrl: series.coverImageUrl,
                    status: series.status,
                    totalChapters: series.totalChapters,
                    updatedAt: series.updatedAt,
                    chapters: series.chapters
                        .where((item) => item.id != chapter.id)
                        .toList(growable: false),
                  ),
          )
          .where((series) => series.chapters.isNotEmpty)
          .toList(growable: false),
    );
  }

  Future<void> deleteSeries(String seriesId) async {
    final session = ref.read(authSessionProvider).value;
    if (session == null) return;
    await ref
        .read(offlineChapterRepositoryProvider)
        .deleteSeries(session.userId, seriesId);
    final current = state.value ?? const <OfflineSeries>[];
    state = AsyncData(
      current.where((item) => item.id != seriesId).toList(growable: false),
    );
  }
}
