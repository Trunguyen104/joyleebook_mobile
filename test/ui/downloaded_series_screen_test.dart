import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/data/repositories/offline_series_repository.dart';
import 'package:joyleebook_mobile/data/repositories/payment_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/chapter.dart';
import 'package:joyleebook_mobile/domain/models/chapter_detail.dart';
import 'package:joyleebook_mobile/domain/models/downloaded_series.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/routing/app_paths.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/bookmark_screen.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/chapter_detail_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/download/widgets/downloaded_series_screen.dart';
import 'package:joyleebook_mobile/ui/download/widgets/offline_series_detail_screen.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_detail_screen.dart';

import '../../testing/fakes/fake_chapter_repository.dart';
import '../../testing/fakes/fake_offline_series_repository.dart';
import '../../testing/fakes/fake_payment_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

void main() {
  final sampleDownloaded = DownloadedSeries(
    id: 's1',
    title: 'Hành Trình Về Phương Đông',
    authorName: 'Nguyên Phong',
    description: 'Tác phẩm kinh điển.',
    coverImageUrl: '',
    status: SeriesStatus.completed,
    totalChapters: 10,
    downloadedChaptersCount: 10,
    totalBytes: 2 * 1024 * 1024, // 2.0 MB
    downloadedAt: DateTime(2026, 11, 1),
  );

  Widget buildApp(FakeOfflineSeriesRepository repo, {VoidCallback? onExplore}) {
    return ProviderScope(
      overrides: [offlineSeriesRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: DownloadedSeriesScreen(onExplore: onExplore),
      ),
    );
  }

  testWidgets('Hiển thị JoyleeEmptyState khi chưa có truyện nào được tải', (
    tester,
  ) async {
    var explored = false;
    final repo = FakeOfflineSeriesRepository();

    await tester.pumpWidget(buildApp(repo, onExplore: () => explored = true));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Chưa có truyện đã tải'), findsOneWidget);
    expect(find.text('Khám phá truyện'), findsOneWidget);

    await tester.tap(find.text('Khám phá truyện'));
    expect(explored, isTrue);
  });

  testWidgets('Hiển thị JoyleeErrorView khi truy vấn SQLite lỗi', (
    tester,
  ) async {
    final repo = FakeOfflineSeriesRepository(shouldThrowError: true);

    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeErrorView), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('Hiển thị danh sách truyện đã tải và thông tin dung lượng', (
    tester,
  ) async {
    final repo = FakeOfflineSeriesRepository(seriesList: [sampleDownloaded]);

    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('1 tác phẩm ngoại tuyến'), findsOneWidget);
    expect(find.text('Dung lượng: 2.0 MB'), findsOneWidget);
    expect(find.text('Hành Trình Về Phương Đông'), findsOneWidget);
    expect(find.text('Nguyên Phong'), findsOneWidget);
    expect(find.text('10/10 chương'), findsOneWidget);
    expect(find.text('2.0 MB'), findsOneWidget);
  });

  testWidgets('Xóa bản tải mở AlertDialog xác nhận và cập nhật giao diện', (
    tester,
  ) async {
    final repo = FakeOfflineSeriesRepository(seriesList: [sampleDownloaded]);

    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Xóa bản tải?'), findsOneWidget);

    await tester.tap(find.text('Xóa bản tải'));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(
      find.text('Đã xóa bản tải "Hành Trình Về Phương Đông"'),
      findsOneWidget,
    );
  });

  testWidgets(
    'SeriesDetailScreen hiển thị đúng số chương thực tế và dung lượng ước tính khi series.totalChapters là 0',
    (tester) async {
      const mockSeries = Series(
        id: 's1',
        title: 'Hành Trình Về Phương Đông',
        authorName: 'Nguyên Phong',
        description: 'Tác phẩm kinh điển.',
        coverImageUrl: '',
        status: SeriesStatus.completed,
        totalChapters: 0,
      );
      const mockChapters = [
        Chapter(id: 'c1', seriesId: 's1', sortOrder: 1, title: 'Ch 1'),
        Chapter(id: 'c2', seriesId: 's1', sortOrder: 2, title: 'Ch 2'),
        Chapter(id: 'c3', seriesId: 's1', sortOrder: 3, title: 'Ch 3'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(
              FakeSeriesRepository([mockSeries]),
            ),
            chapterRepositoryProvider.overrideWithValue(
              FakeChapterRepository(mockChapters),
            ),
            offlineSeriesRepositoryProvider.overrideWithValue(
              FakeOfflineSeriesRepository(),
            ),
            paymentRepositoryProvider.overrideWithValue(
              FakePaymentRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SeriesDetailScreen(seriesId: 's1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_download_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.cloud_download_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Tải trọn bộ tác phẩm?'), findsOneWidget);
      expect(find.textContaining('3 chương'), findsOneWidget);
      expect(find.textContaining('~150 KB'), findsOneWidget);
      expect(find.text('Tải ngay'), findsOneWidget);
    },
  );

  testWidgets(
    'ChapterDetailScreen hiển thị badge Ngoại tuyến khi đọc chương từ SQLite',
    (tester) async {
      const offlineDetail = ChapterDetail(
        id: 'c1',
        seriesId: 's1',
        title: 'Chương 1',
        content: 'Nội dung đọc ngoại tuyến rất dài và hay.',
        sortOrder: 1,
        totalChapters: 10,
        status: 1,
        isOffline: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chapterRepositoryProvider.overrideWithValue(
              FakeChapterRepository(const [], false, offlineDetail),
            ),
            offlineSeriesRepositoryProvider.overrideWithValue(
              FakeOfflineSeriesRepository(),
            ),
            paymentRepositoryProvider.overrideWithValue(
              FakePaymentRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ChapterDetailScreen(
              seriesId: 's1',
              chapterId: 'c1',
              seriesTitle: 'Hành Trình Về Phương Đông',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ngoại tuyến'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    },
  );

  testWidgets(
    'BookmarkScreen tab Đã tải điều hướng sang OfflineSeriesDetailScreen và mở đọc offline tức thì',
    (tester) async {
      const ch1 = Chapter(
        id: 'c1',
        seriesId: 's1',
        sortOrder: 1,
        title: 'Một người huyền bí',
      );
      const ch1Detail = ChapterDetail(
        id: 'c1',
        seriesId: 's1',
        title: 'Một người huyền bí',
        content: 'Nội dung chương 1 ngoại tuyến.',
        sortOrder: 1,
        totalChapters: 10,
        status: 1,
        isOffline: true,
      );
      final repo = FakeOfflineSeriesRepository(
        seriesList: [sampleDownloaded],
        chaptersMap: {
          's1': [ch1],
        },
        detailsMap: {'c1': ch1Detail},
      );

      final router = GoRouter(
        initialLocation: AppPaths.bookmarks,
        routes: [
          GoRoute(
            path: AppPaths.bookmarks,
            builder: (_, _) => const BookmarkScreen(),
            routes: [
              GoRoute(
                path: 'downloads/:seriesId',
                builder: (_, state) => OfflineSeriesDetailScreen(
                  seriesId: state.pathParameters['seriesId']!,
                  initialSeries: state.extra is DownloadedSeries
                      ? state.extra as DownloadedSeries
                      : null,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/series/:seriesId/chapters/:chapterId',
            builder: (_, state) => ChapterDetailScreen(
              seriesId: state.pathParameters['seriesId']!,
              chapterId: state.pathParameters['chapterId']!,
              seriesTitle: state.extra as String? ?? '',
              isOfflineMode: state.uri.queryParameters['offline'] == '1',
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(
              FakeSeriesRepository([]),
            ),
            offlineSeriesRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đã tải'));
      await tester.pumpAndSettle();

      expect(find.text('1 tác phẩm ngoại tuyến'), findsOneWidget);
      await tester.tap(find.text('Hành Trình Về Phương Đông'));
      await tester.pumpAndSettle();

      expect(find.byType(OfflineSeriesDetailScreen), findsOneWidget);
      expect(find.text('Đọc ngay'), findsOneWidget);

      await tester.tap(find.text('Đọc ngay'));
      await tester.pumpAndSettle();

      expect(find.byType(ChapterDetailScreen), findsOneWidget);
      expect(find.text('Nội dung chương 1 ngoại tuyến.'), findsOneWidget);
      expect(find.text('Ngoại tuyến'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    },
  );
}
