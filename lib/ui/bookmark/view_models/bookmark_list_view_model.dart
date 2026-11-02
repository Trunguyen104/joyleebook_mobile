import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/series_repository.dart';
import '../../../domain/models/series.dart';
import 'bookmark_status_view_model.dart';

final bookmarkListViewModelProvider =
    AsyncNotifierProvider<BookmarkListViewModel, List<Series>>(
      BookmarkListViewModel.new,
      retry: (retryCount, error) => null,
    );

class BookmarkListViewModel extends AsyncNotifier<List<Series>> {
  final Set<String> _inFlightIds = {};

  @override
  Future<List<Series>> build() => _loadBookmarks();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadBookmarks);
  }

  Future<List<Series>> _loadBookmarks() async {
    final bookmarks = await ref
        .read(seriesRepositoryProvider)
        .getBookmarkedSeries();
    ref
        .read(bookmarkStatusViewModelProvider.notifier)
        .replaceBookmarkedIds(bookmarks.map((series) => series.id));
    return bookmarks;
  }

  Future<bool> removeBookmark(String seriesId) async {
    final current = state.value;
    if (current == null || _inFlightIds.contains(seriesId)) return false;
    final index = current.indexWhere((series) => series.id == seriesId);
    if (index == -1) return false;

    final original = current[index];
    _inFlightIds.add(seriesId);
    state = AsyncData(
      current.where((series) => series.id != seriesId).toList(growable: false),
    );
    ref
        .read(bookmarkStatusViewModelProvider.notifier)
        .setStatus(seriesId, false);

    try {
      await ref.read(seriesRepositoryProvider).toggleBookmark(seriesId, false);
      return true;
    } catch (_) {
      final latest = state.value ?? current;
      final restored = List<Series>.from(latest);
      restored.insert(
        index < restored.length ? index : restored.length,
        original,
      );
      state = AsyncData(restored);
      ref
          .read(bookmarkStatusViewModelProvider.notifier)
          .setStatus(seriesId, true);
      return false;
    } finally {
      _inFlightIds.remove(seriesId);
    }
  }

  void updateBookmarkLocally(Series series, bool isBookmarked) {
    final current = state.value;
    if (current == null) return;

    final updated = current
        .where((item) => item.id != series.id)
        .toList(growable: true);
    if (isBookmarked) {
      updated.insert(0, series.copyWith(isBookmarked: true));
    }
    state = AsyncData(updated);
    ref
        .read(bookmarkStatusViewModelProvider.notifier)
        .setStatus(series.id, isBookmarked);
  }
}
