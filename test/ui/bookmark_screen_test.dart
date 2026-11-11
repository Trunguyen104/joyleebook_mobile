import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joyleebook_mobile/data/repositories/offline_series_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/chapter.dart';
import 'package:joyleebook_mobile/domain/models/downloaded_series.dart';
import 'package:joyleebook_mobile/domain/models/reading_history.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/routing/app_paths.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/bookmark_list_screen.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/bookmark_screen.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/reading_history_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/download/widgets/offline_series_detail_screen.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_card.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_rating_card.dart';

import '../../testing/fakes/fake_offline_series_repository.dart';
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

final _downloadedSeries = DownloadedSeries(
  id: 'series-1',
  title: 'Hành Trình Về Phương Đông',
  authorName: 'Nguyên Phong',
  description: 'Tác phẩm kinh điển.',
  coverImageUrl: '',
  status: SeriesStatus.completed,
  genres: const ['Tâm Linh'],
  totalChapters: 2,
  downloadedChaptersCount: 2,
  totalBytes: 1024 * 500,
  downloadedAt: DateTime(2026, 11, 1),
);

Widget _buildApp(
  FakeSeriesRepository seriesRepository, {
  FakeOfflineSeriesRepository? offlineRepository,
}) => ProviderScope(
  overrides: [
    seriesRepositoryProvider.overrideWithValue(seriesRepository),
    offlineSeriesRepositoryProvider.overrideWithValue(
      offlineRepository ?? FakeOfflineSeriesRepository(),
    ),
  ],
  child: MaterialApp(theme: AppTheme.light, home: const BookmarkScreen()),
);

Widget _buildRouterApp(
  FakeSeriesRepository seriesRepository, {
  FakeOfflineSeriesRepository? offlineRepository,
}) {
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
            path: 'downloads/:seriesId',
            builder: (context, state) => OfflineSeriesDetailScreen(
              seriesId: state.pathParameters['seriesId']!,
              initialSeries: state.extra is DownloadedSeries
                  ? state.extra as DownloadedSeries
                  : null,
            ),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      seriesRepositoryProvider.overrideWithValue(seriesRepository),
      offlineSeriesRepositoryProvider.overrideWithValue(
        offlineRepository ?? FakeOfflineSeriesRepository(),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

void main() {
  testWidgets(
    'Hiển thị 3 tab trên dưới AppBar và thông báo trống riêng cho từng tab',
    (tester) async {
      await tester.pumpWidget(_buildApp(FakeSeriesRepository([])));
      await tester.pumpAndSettle();

      // Kiểm tra 3 tab
      expect(find.text('Đang đọc'), findsOneWidget);
      expect(find.text('Đã lưu'), findsOneWidget);
      expect(find.text('Đã tải'), findsOneWidget);

      // Tab 1: Đang đọc
      expect(find.text('Chưa có lịch sử đọc'), findsOneWidget);
      expect(find.text('Khám phá truyện'), findsOneWidget);

      // Tab 2: Đã lưu
      await tester.tap(find.text('Đã lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Tủ sách đang trống'), findsOneWidget);
      expect(find.text('Khám phá truyện'), findsOneWidget);

      // Tab 3: Đã tải
      await tester.tap(find.text('Đã tải'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có truyện đã tải'), findsOneWidget);
      expect(find.text('Khám phá truyện'), findsOneWidget);
    },
  );

  testWidgets('Tự tải lại dữ liệu khi quay lại tab tủ sách', (tester) async {
    final repository = FakeSeriesRepository.withHistory([
      _bookmarkedSeries,
    ], readingHistory: _readingHistory);
    final tickerEnabled = ValueNotifier<bool>(false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(repository),
          offlineSeriesRepositoryProvider.overrideWithValue(
            FakeOfflineSeriesRepository(),
          ),
        ],
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

    // Tab được mở lại -> dữ liệu được tải mới.
    tickerEnabled.value = true;
    await tester.pumpAndSettle();

    expect(repository.bookmarkListCallCount, greaterThan(bookmarkCalls));
    expect(repository.readingHistoryCallCount, greaterThan(historyCalls));
  });

  testWidgets('Hiển thị lỗi độc lập và cho phép thử lại ở từng tab', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeSeriesRepository([], true)));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeErrorView), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeErrorView), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
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

    // Tab Đang đọc
    expect(find.text('Hành Trình Về Phương Đông'), findsOneWidget);
    expect(find.textContaining('Hội thảo khoa học'), findsOneWidget);
    expect(find.text('Tiến độ 40%'), findsOneWidget);

    // Tab Đã lưu
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Hành Trình Về Phương Đông'), findsOneWidget);
  });

  testWidgets('Hiển thị dạng List cho tab Đang đọc và tab Đã lưu', (
    tester,
  ) async {
    final bookmarks = List<Series>.generate(
      3,
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

    expect(find.byType(HistoryListTile), findsNWidgets(3));
    expect(find.byType(GridView), findsNothing);

    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();

    expect(find.byType(SeriesCard), findsNWidgets(3));
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('Bỏ lưu ở tab Đã lưu cập nhật danh sách ngay', (tester) async {
    await tester.pumpWidget(
      _buildApp(FakeSeriesRepository([_bookmarkedSeries])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đã lưu'));
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

  testWidgets(
    'Bấm vào series đã tải trong tab Đã tải điều hướng sang OfflineSeriesDetailScreen giản lược không có rating',
    (tester) async {
      final offlineRepo = FakeOfflineSeriesRepository(
        seriesList: [_downloadedSeries],
        chaptersMap: {
          'series-1': const [
            Chapter(
              id: 'c1',
              seriesId: 'series-1',
              sortOrder: 1,
              title: 'Chương 1',
            ),
            Chapter(
              id: 'c2',
              seriesId: 'series-1',
              sortOrder: 2,
              title: 'Chương 2',
            ),
          ],
        },
      );

      await tester.pumpWidget(
        _buildRouterApp(
          FakeSeriesRepository([]),
          offlineRepository: offlineRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đã tải'));
      await tester.pumpAndSettle();

      expect(find.text('Hành Trình Về Phương Đông'), findsOneWidget);
      await tester.tap(find.text('Hành Trình Về Phương Đông'));
      await tester.pumpAndSettle();

      expect(find.byType(OfflineSeriesDetailScreen), findsOneWidget);
      expect(find.byType(SeriesRatingCard), findsNothing);
      expect(find.text('Bình luận'), findsNothing);
      expect(find.text('Lưu tủ sách'), findsNothing);
      expect(find.text('Ngoại tuyến • 500.0 KB'), findsOneWidget);
      expect(find.text('Đọc ngay'), findsOneWidget);
      expect(find.text('Tóm tắt'), findsOneWidget);
      expect(find.text('Chương (2)'), findsOneWidget);
    },
  );

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
        offlineRepository: FakeOfflineSeriesRepository(
          seriesList: [_downloadedSeries],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HistoryListTile), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(SeriesCard), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Đã tải'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
