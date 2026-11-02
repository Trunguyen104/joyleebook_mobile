import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/bookmark_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_detail_screen.dart';

import '../../testing/fakes/fake_chapter_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

const _bookmarkedSeries = Series(
  id: 'series-1',
  title: 'Hành Trình Về Phương Đông',
  authorName: 'Nguyên Phong',
  description: 'Tác phẩm kinh điển.',
  coverImageUrl: '',
  status: SeriesStatus.completed,
  isBookmarked: true,
);

Widget _buildApp(
  FakeSeriesRepository seriesRepository, {
  FakeChapterRepository? chapterRepository,
}) {
  return ProviderScope(
    overrides: [
      seriesRepositoryProvider.overrideWithValue(seriesRepository),
      if (chapterRepository != null)
        chapterRepositoryProvider.overrideWithValue(chapterRepository),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const BookmarkScreen()),
  );
}

void main() {
  testWidgets('Hiển thị trạng thái trống và gợi ý khám phá truyện', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeSeriesRepository([])));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Tủ sách đang trống'), findsOneWidget);
    expect(find.text('Khám phá truyện'), findsOneWidget);
  });

  testWidgets('Hiển thị lỗi và cho phép thử lại', (tester) async {
    final repository = FakeSeriesRepository([], true);
    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeErrorView), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('Hiển thị truyện đã lưu và mở được chi tiết', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        FakeSeriesRepository([_bookmarkedSeries]),
        chapterRepository: FakeChapterRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_bookmarkedSeries.title), findsOneWidget);
    await tester.tap(find.text(_bookmarkedSeries.title));
    await tester.pumpAndSettle();

    expect(find.byType(SeriesDetailScreen), findsOneWidget);
    expect(find.text('Đã lưu'), findsOneWidget);
  });

  testWidgets('Bỏ lưu cập nhật danh sách ngay và hiển thị trạng thái trống', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(FakeSeriesRepository([_bookmarkedSeries])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bỏ lưu'));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(
      find.text('Đã bỏ lưu "${_bookmarkedSeries.title}" khỏi tủ sách.'),
      findsOneWidget,
    );
  });

  testWidgets('Nút làm mới tải lại danh sách tủ sách', (tester) async {
    final repository = FakeSeriesRepository([_bookmarkedSeries]);
    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();
    final initialCalls = repository.bookmarkListCallCount;

    await tester.tap(find.byTooltip('Làm mới tủ sách'));
    await tester.pumpAndSettle();

    expect(repository.bookmarkListCallCount, initialCalls + 1);
  });
}
