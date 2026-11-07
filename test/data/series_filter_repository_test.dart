import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';

import '../../testing/fakes/fake_series_repository.dart';

void main() {
  group('FakeSeriesRepository - Filter & Search Unit Tests', () {
    late FakeSeriesRepository repository;

    final testSeries = [
      const Series(
        id: '1',
        title: 'Hành Trình Về Phương Đông',
        authorName: 'Nguyên Phong',
        description: 'Tâm linh triết học phương Đông',
        coverImageUrl: '',
        status: SeriesStatus.completed,
        genres: ['Tâm Linh', 'Triết Học'],
      ),
      const Series(
        id: '2',
        title: 'Thần Đạo Đan Tôn',
        authorName: 'Cô Đơn Địa Phi',
        description: 'Tu tiên huyền ảo đỉnh phong',
        coverImageUrl: '',
        status: SeriesStatus.ongoing,
        genres: ['Kỳ Ảo', 'Tu Tiên', 'Hành Động'],
      ),
      const Series(
        id: '3',
        title: 'Sherlock Holmes Toàn Tập',
        authorName: 'Arthur Conan Doyle',
        description: 'Trinh thám kinh điển thế giới',
        coverImageUrl: '',
        status: SeriesStatus.completed,
        genres: ['Trinh Thám'],
      ),
    ];

    setUp(() {
      repository = FakeSeriesRepository(testSeries);
    });

    test('Lấy toàn bộ truyện khi không có bộ lọc', () async {
      final result = await repository.getSeriesList();
      expect(result.length, equals(3));
    });

    test('Tìm kiếm theo từ khóa tên truyện hoặc tác giả', () async {
      final byTitle = await repository.getSeriesList(
        searchQuery: 'Phương Đông',
      );
      expect(byTitle.length, equals(1));
      expect(byTitle.first.title, equals('Hành Trình Về Phương Đông'));

      final byAuthor = await repository.getSeriesList(searchQuery: 'Arthur');
      expect(byAuthor.length, equals(1));
      expect(byAuthor.first.authorName, equals('Arthur Conan Doyle'));
    });

    test('Lọc tác phẩm theo thể loại', () async {
      final fantasySeries = await repository.getSeriesList(genre: 'Kỳ Ảo');
      expect(fantasySeries.length, equals(1));
      expect(fantasySeries.first.id, equals('2'));

      final nonExistentGenre = await repository.getSeriesList(
        genre: 'Không Tồn Tại',
      );
      expect(nonExistentGenre, isEmpty);
    });

    test('Lọc tác phẩm theo trạng thái phát hành', () async {
      final ongoingList = await repository.getSeriesList(
        status: SeriesStatus.ongoing,
      );
      expect(ongoingList.length, equals(1));
      expect(ongoingList.first.id, equals('2'));

      final completedList = await repository.getSeriesList(
        status: SeriesStatus.completed,
      );
      expect(completedList.length, equals(2));
    });

    test('Kết hợp lọc đa tiêu chí: Từ khóa + Thể loại + Trạng thái', () async {
      final combined = await repository.getSeriesList(
        searchQuery: 'Thần Đạo',
        genre: 'Kỳ Ảo',
        status: SeriesStatus.ongoing,
      );
      expect(combined.length, equals(1));
      expect(combined.first.title, equals('Thần Đạo Đan Tôn'));

      final noMatch = await repository.getSeriesList(
        searchQuery: 'Thần Đạo',
        genre: 'Trinh Thám',
        status: SeriesStatus.completed,
      );
      expect(noMatch, isEmpty);
    });
  });
}
