import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/genre_repository.dart';
import '../../../domain/models/genre.dart';

/// RIVERPOD PROVIDER: Quản lý danh sách thể loại
final genreListViewModelProvider =
    AsyncNotifierProvider<GenreListViewModel, List<Genre>>(
  GenreListViewModel.new,
  retry: (retryCount, error) => null,
);

/// VIEWMODEL - Quản lý danh mục thể loại
/// Bước 4 trong kiến trúc Compass App:
/// Kế thừa `AsyncNotifier<List<Genre>>` để quản lý trạng thái tải danh mục thể loại.
class GenreListViewModel extends AsyncNotifier<List<Genre>> {
  @override
  Future<List<Genre>> build() {
    return ref.watch(genreRepositoryProvider).getGenres();
  }

  /// Kéo để làm mới danh mục thể loại
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(genreRepositoryProvider).getGenres(),
    );
  }
}
