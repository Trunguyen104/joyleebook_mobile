import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/reading_history.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/routing/app_paths.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/bookmark_list_screen.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/bookmark_screen.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/library_series_card.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/reading_history_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';

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

final _readingHistory = [
  ReadingHistory(
    seriesId: _bookmarkedSeries.id,
    series: _bookmarkedSeries,
    chapterTitle: 'Hội thảo khoa học',
    chapterNumber: 2,
    progress: 0.4,
    lastReadAt: DateTime(2026, 11, 1),
  ),
];

Widget _buildApp(FakeSeriesRepository seriesRepository) => ProviderScope(
  overrides: [seriesRepositoryProvider.overrideWithValue(seriesRepository)],
  child: MaterialApp(theme: AppTheme.light, home: const BookmarkScreen()),
);

Widget _buildRouterApp(FakeSeriesRepository seriesRepository) {
  final router = GoRouter(
    initialLocation: AppPaths.bookmarks,
    routes: [
      GoRoute(
        path: AppPaths.bookmarks,
        builder: (context, state) => const BookmarkScreen(),
        routes: [
          GoRoute(
            path: 'all',
            builder: (context, state) => const BookmarkListScreen(),
          ),
          GoRoute(
            path: 'history',
            builder: (context, state) => const ReadingHistoryScreen(),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [seriesRepositoryProvider.overrideWithValue(seriesRepository)],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

void main() {
  testWidgets('Hiển thị thông báo trống riêng cho lịch sử và tủ sách', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeSeriesRepository([])));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có lịch sử đọc'), findsOneWidget);
    expect(find.text('Tủ sách đang trống'), findsOneWidget);
    expect(find.text('Khám phá truyện'), findsNWidgets(2));
  });

  testWidgets('Tự tải lại dữ liệu khi quay lại tab tủ sách', (tester) async {
    final repository = FakeSeriesRepository.withHistory([
      _bookmarkedSeries,
    ], readingHistory: _readingHistory);
    final tickerEnabled = ValueNotifier<bool>(false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ValueListenableBuilder<bool>(
            valueListenable: tickerEnabled,
            builder: (context, enabled, child) =>
                TickerMode(enabled: enabled, child: child!),
            child: const BookmarkScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bookmarkCalls = repository.bookmarkListCallCount;
    final historyCalls = repository.readingHistoryCallCount;

    // Tab được mở lại -> cả hai phần dữ liệu đều được tải mới.
    tickerEnabled.value = true;
    await tester.pumpAndSettle();

    expect(repository.bookmarkListCallCount, greaterThan(bookmarkCalls));
    expect(repository.readingHistoryCallCount, greaterThan(historyCalls));
  });

  testWidgets('Hiển thị lỗi độc lập và cho phép thử lại từng phần', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeSeriesRepository([], true)));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeErrorView), findsNWidgets(2));
    expect(find.text('Thử lại'), findsNWidgets(2));
  });

  testWidgets('Hiển thị lịch sử và bookmark với chương, tiến độ', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        FakeSeriesRepository.withHistory([
          _bookmarkedSeries,
        ], readingHistory: _readingHistory),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hành Trình Về Phương Đông'), findsNWidgets(2));
    expect(find.textContaining('Hội thảo khoa học'), findsOneWidget);
    expect(find.text('Tiến độ 40%'), findsOneWidget);
  });

  testWidgets('Tủ sách chỉ hiển thị bốn truyện gần nhất trong mỗi danh sách', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bookmarks = List<Series>.generate(
      6,
      (index) => Series(
        id: 'series-$index',
        title: 'Truyện đã lưu $index',
        authorName: _bookmarkedSeries.authorName,
        description: _bookmarkedSeries.description,
        coverImageUrl: _bookmarkedSeries.coverImageUrl,
        status: _bookmarkedSeries.status,
        isBookmarked: true,
      ),
    );
    final history = bookmarks
        .map(
          (series) => ReadingHistory(
            seriesId: series.id,
            series: series,
            chapterTitle: 'Chương gần đây',
            chapterNumber: 1,
            progress: 0.4,
            lastReadAt: DateTime(2026, 11, 1),
          ),
        )
        .toList();

    await tester.pumpWidget(
      _buildApp(
        FakeSeriesRepository.withHistory(bookmarks, readingHistory: history),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LibrarySeriesCard), findsNWidgets(8));
    expect(find.byType(GridView), findsNWidgets(2));
    expect(find.text('Truyện đã lưu 0'), findsNWidgets(2));
    expect(find.text('Truyện đã lưu 3'), findsNWidgets(2));
    expect(find.text('Truyện đã lưu 4'), findsNothing);
    expect(find.text('Tiến độ 40%'), findsNWidgets(4));
    expect(find.textContaining('+2 truyện'), findsNothing);
    expect(find.byKey(const ValueKey('view-all-bookmarks')), findsNothing);
    final wideGrid = tester.widget<GridView>(find.byType(GridView).first);
    expect(
      (wideGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      4,
    );

    tester.view.physicalSize = const Size(390, 1000);
    await tester.pumpWidget(
      _buildApp(
        FakeSeriesRepository.withHistory(bookmarks, readingHistory: history),
      ),
    );
    await tester.pumpAndSettle();
    final narrowGrid = tester.widget<GridView>(find.byType(GridView).first);
    expect(
      (narrowGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
  });

  testWidgets('Bỏ lưu cập nhật danh sách ngay', (tester) async {
    await tester.pumpWidget(
      _buildApp(FakeSeriesRepository([_bookmarkedSeries])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bỏ lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Tủ sách đang trống'), findsOneWidget);
    expect(
      find.text('Đã bỏ lưu "${_bookmarkedSeries.title}" khỏi tủ sách.'),
      findsOneWidget,
    );
  });

  testWidgets('Danh sách bookmark có nút thùng rác để xóa truyện', (
    tester,
  ) async {
    final repository = FakeSeriesRepository([_bookmarkedSeries]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: AppTheme.light, home: BookmarkListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Xóa khỏi tủ sách'), findsOneWidget);
    await tester.tap(find.byTooltip('Xóa khỏi tủ sách'));
    await tester.pumpAndSettle();

    expect(find.text('Tủ sách đang trống'), findsOneWidget);
  });

  testWidgets('BookmarkListScreen không hiển thị hoặc tải tiến độ đọc', (
    tester,
  ) async {
    final repository = FakeSeriesRepository.withHistory([
      _bookmarkedSeries,
    ], readingHistory: _readingHistory);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(theme: AppTheme.light, home: BookmarkListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tiến độ 40%'), findsNothing);
    expect(repository.readingProgressCallCount, 0);
  });

  testWidgets('View All mở màn hình lịch sử và danh sách bookmark', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildRouterApp(
        FakeSeriesRepository.withHistory([
          _bookmarkedSeries,
        ], readingHistory: _readingHistory),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xem tất cả').first);
    await tester.pumpAndSettle();
    expect(find.byType(ReadingHistoryScreen), findsOneWidget);
    expect(find.text('Lịch sử đọc'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem tất cả').last);
    await tester.pumpAndSettle();
    expect(find.byType(BookmarkListScreen), findsOneWidget);
    expect(find.text('Truyện đã lưu'), findsOneWidget);
  });

  testWidgets('Không bị RenderFlex overflow trên màn hình hẹp (360x640)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _buildApp(
        FakeSeriesRepository.withHistory([
          _bookmarkedSeries,
        ], readingHistory: _readingHistory),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LibrarySeriesCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
