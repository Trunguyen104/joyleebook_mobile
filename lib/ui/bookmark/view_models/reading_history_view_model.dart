import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/series_repository.dart';
import '../../../domain/models/reading_history.dart';
import '../../auth/view_models/auth_session_view_model.dart';

final readingHistoryViewModelProvider =
    AsyncNotifierProvider<ReadingHistoryViewModel, List<ReadingHistory>>(
      ReadingHistoryViewModel.new,
      retry: (retryCount, error) => null,
    );

class ReadingHistoryViewModel extends AsyncNotifier<List<ReadingHistory>> {
  @override
  Future<List<ReadingHistory>> build() {
    ref.listen(authSessionProvider, (prev, next) {
      if (prev?.value?.userId != next.value?.userId) {
        refresh();
      }
    });
    return ref.watch(seriesRepositoryProvider).getReadingHistory();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(seriesRepositoryProvider).getReadingHistory(),
    );
  }
}
