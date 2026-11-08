import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookmarkStatusViewModelProvider =
    NotifierProvider<BookmarkStatusViewModel, Map<String, bool>>(
      BookmarkStatusViewModel.new,
    );

class BookmarkStatusViewModel extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  void setStatus(String seriesId, bool isBookmarked) {
    state = {...state, seriesId: isBookmarked};
  }

  void replaceBookmarkedIds(Iterable<String> bookmarkedIds) {
    final statuses = {for (final id in state.keys) id: false};
    for (final id in bookmarkedIds) {
      statuses[id] = true;
    }
    state = statuses;
  }
}
