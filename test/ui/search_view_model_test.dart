import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/search/view_models/search_view_model.dart';

import '../../testing/fakes/fake_series_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleSeries = [
    const Series(
      id: 's1',
      title: 'Đấu Phá Thương Khung',
      authorName: 'Thiên Tằm Thổ Đậu',
      description: 'Tu luyện dị hỏa',
      coverImageUrl: '',
      status: SeriesStatus.ongoing,
      genres: ['Kỳ Ảo'],
    ),
    const Series(
      id: 's2',
      title: 'Sát Thủ Về Hưu',
      authorName: 'John Wick',
      description: 'Hành động bắn súng',
      coverImageUrl: '',
      status: SeriesStatus.completed,
      genres: ['Hành Động'],
    ),
  ];

  group('SearchViewModel - Unit Tests', () {
    test('Khởi tạo ViewModel tải toàn bộ danh sách truyện', () async {
      final fakeRepo = FakeSeriesRepository(sampleSeries);
      final container = ProviderContainer(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final initialValue = await container.read(searchViewModelProvider.future);
      expect(initialValue.length, 2);
      expect(container.read(searchViewModelProvider.notifier).isFiltered, false);
    });

    test('Lọc theo thể loại cập nhật state chính xác', () async {
      final fakeRepo = FakeSeriesRepository(sampleSeries);
      final container = ProviderContainer(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(searchViewModelProvider.future);
      final vm = container.read(searchViewModelProvider.notifier);

      await vm.filterByGenre('Kỳ Ảo');
      final filteredList = container.read(searchViewModelProvider).value;

      expect(filteredList?.length, 1);
      expect(filteredList?.first.title, 'Đấu Phá Thương Khung');
      expect(vm.selectedGenre, 'Kỳ Ảo');
      expect(vm.isFiltered, true);

      // Bấm lại thể loại đang active -> hủy lọc
      await vm.filterByGenre('Kỳ Ảo');
      expect(vm.selectedGenre, null);
      expect(container.read(searchViewModelProvider).value?.length, 2);
    });

    test('Lọc theo trạng thái phát hành (ongoing / completed)', () async {
      final fakeRepo = FakeSeriesRepository(sampleSeries);
      final container = ProviderContainer(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(searchViewModelProvider.future);
      final vm = container.read(searchViewModelProvider.notifier);

      await vm.filterByStatus(SeriesStatus.completed);
      final completedList = container.read(searchViewModelProvider).value;

      expect(completedList?.length, 1);
      expect(completedList?.first.title, 'Sát Thủ Về Hưu');
      expect(vm.selectedStatus, SeriesStatus.completed);
    });

    test('Tìm kiếm với immediate = true trả kết quả tức thì', () async {
      final fakeRepo = FakeSeriesRepository(sampleSeries);
      final container = ProviderContainer(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(searchViewModelProvider.future);
      final vm = container.read(searchViewModelProvider.notifier);

      await vm.search('John Wick', immediate: true);

      final searchResults = container.read(searchViewModelProvider).value;
      expect(searchResults?.length, 1);
      expect(searchResults?.first.authorName, 'John Wick');
    });

    test('Quản lý Lịch sử tìm kiếm (add, remove, clear)', () async {
      final fakeRepo = FakeSeriesRepository(sampleSeries);
      final container = ProviderContainer(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(searchViewModelProvider.future);
      final vm = container.read(searchViewModelProvider.notifier);

      await vm.addRecentSearch('tiên hiệp');
      await vm.addRecentSearch('huyền huyễn');
      expect(vm.recentSearches.contains('tiên hiệp'), true);
      expect(vm.recentSearches.contains('huyền huyễn'), true);

      await vm.removeRecentSearch('tiên hiệp');
      expect(vm.recentSearches.contains('tiên hiệp'), false);

      await vm.clearRecentSearches();
      expect(vm.recentSearches.isEmpty, true);
    });

    test('ClearFilters reset toàn bộ từ khóa và bộ lọc', () async {
      final fakeRepo = FakeSeriesRepository(sampleSeries);
      final container = ProviderContainer(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(searchViewModelProvider.future);
      final vm = container.read(searchViewModelProvider.notifier);

      await vm.filterByGenre('Kỳ Ảo');
      await vm.filterByStatus(SeriesStatus.ongoing);
      expect(vm.isFiltered, true);

      await vm.clearFilters();
      expect(vm.isFiltered, false);
      expect(vm.selectedGenre, null);
      expect(vm.selectedStatus, null);
      expect(vm.currentQuery, '');
    });
  });
}
