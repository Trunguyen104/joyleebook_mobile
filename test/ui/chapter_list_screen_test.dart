import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/data/services/reading_preferences_service.dart';
import 'package:joyleebook_mobile/domain/models/auth_session.dart';
import 'package:joyleebook_mobile/domain/models/chapter.dart';
import 'package:joyleebook_mobile/domain/models/reading_progress.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
import 'package:joyleebook_mobile/ui/chapter/view_models/chapter_list_view_model.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/chapter_item.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/chapter_list_screen.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/resume_reading_bar.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_chapter_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

void main() {
  const seriesId = 'series-123';
  const seriesTitle = 'Hành Trình Về Phương Đông';

  final mockChapters = [
    const Chapter(
      id: 'ch-1',
      seriesId: seriesId,
      sortOrder: 1,
      title: 'Một người huyền bí',
      isFree: true,
      durationMinutes: 15,
      isActive: false,
    ),
    const Chapter(
      id: 'ch-2',
      seriesId: seriesId,
      sortOrder: 2,
      title: 'Hội thảo khoa học',
      isFree: true,
      durationMinutes: 18,
      readPercentage: 0.5,
      isActive: true, // Chương đang đọc dở
    ),
  ];

  testWidgets('Hiển thị JoyleeEmptyState khi bộ truyện chưa có chương nào', (
    tester,
  ) async {
    final fakeRepo = FakeChapterRepository([]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [chapterRepositoryProvider.overrideWithValue(fakeRepo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ChapterListScreen(
            seriesId: seriesId,
            seriesTitle: seriesTitle,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Chưa có chương nào'), findsOneWidget);
    expect(find.text('Tải lại'), findsOneWidget);
  });

  testWidgets(
    'Hiển thị JoyleeErrorView kèm nút Thử lại khi tải danh sách chương thất bại',
    (tester) async {
      final fakeRepo = FakeChapterRepository([], true); // Báo lỗi

      await tester.pumpWidget(
        ProviderScope(
          overrides: [chapterRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ChapterListScreen(
              seriesId: seriesId,
              seriesTitle: seriesTitle,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(JoyleeErrorView), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );

  testWidgets(
    'Hiển thị danh sách chương và thanh ResumeReadingBar khi có chương đang đọc dở',
    (tester) async {
      final fakeRepo = FakeChapterRepository(mockChapters);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [chapterRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ChapterListScreen(
              seriesId: seriesId,
              seriesTitle: seriesTitle,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề màn hình
      expect(find.text(seriesTitle), findsOneWidget);
      expect(find.text('Danh sách chương'), findsOneWidget);

      // Kiểm tra danh sách thẻ chương ChapterItem
      expect(find.byType(ChapterItem), findsNWidgets(2));
      expect(find.text('Ch. 1: Một người huyền bí'), findsOneWidget);
      expect(find.text('Ch. 2: Hội thảo khoa học'), findsOneWidget);

      // Kiểm tra thanh ResumeReadingBar ghim đáy xuất hiện do có chương isActive: true
      expect(find.byType(ResumeReadingBar), findsOneWidget);
      expect(find.text('Đọc tiếp Ch. 2 (50%)'), findsOneWidget);
    },
  );

  List<Chapter> buildChapters(int count) => List.generate(
    count,
    (index) => Chapter(
      id: 'ch-${index + 1}',
      seriesId: seriesId,
      sortOrder: index + 1,
      title: 'Chương ${index + 1}',
      durationMinutes: 15,
    ),
  );

  testWidgets('Ưu tiên tiến độ đọc từ server khi đã đăng nhập', (tester) async {
    final fakeSeriesRepo = FakeSeriesRepository()
      ..readingProgressDetail = const ReadingProgress(
        seriesId: seriesId,
        chapterId: 'ch-10',
        chapterSortOrder: 10,
        progress: 0.4,
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chapterRepositoryProvider.overrideWithValue(
            FakeChapterRepository(buildChapters(12)),
          ),
          seriesRepositoryProvider.overrideWithValue(fakeSeriesRepo),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              savedSession: const AuthSession(
                userId: 'user-1',
                username: 'reader',
                role: UserRole.reader,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ChapterListScreen(
            seriesId: seriesId,
            seriesTitle: seriesTitle,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(fakeSeriesRepo.readingProgressDetailCallCount, greaterThan(0));
    expect(find.text('Đọc tiếp Ch. 10 (40%)'), findsOneWidget);
  });

  testWidgets('Dùng tiến độ cục bộ khi chưa đăng nhập', (tester) async {
    final prefs = ReadingPreferencesService();
    await prefs.saveReadingProgress(
      seriesId: seriesId,
      chapterId: 'ch-3',
      sortOrder: 3,
      readPercentage: 0.6,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chapterRepositoryProvider.overrideWithValue(
            FakeChapterRepository(buildChapters(5)),
          ),
          readingPreferencesServiceProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ChapterListScreen(
            seriesId: seriesId,
            seriesTitle: seriesTitle,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Đọc tiếp Ch. 3 (60%)'), findsOneWidget);
  });

  test('Cập nhật chương đang đọc tại chỗ khi trình đọc ghi tiến độ', () async {
    final container = ProviderContainer(
      overrides: [
        chapterRepositoryProvider.overrideWithValue(
          FakeChapterRepository(buildChapters(10)),
        ),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    final provider = chapterListViewModelProvider(seriesId);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(provider.future);

    container
        .read(provider.notifier)
        .updateProgressLocally(
          chapterId: 'ch-8',
          sortOrder: 8,
          progress: 0.3,
          isCompleted: false,
        );

    final chapters = container.read(provider).value!;
    final activeChapter = chapters.firstWhere((chapter) => chapter.isActive);
    expect(activeChapter.id, 'ch-8');
    expect(activeChapter.readPercentage, 0.3);
    expect(
      chapters
          .where((chapter) => chapter.sortOrder < 8)
          .every((chapter) => chapter.isCompleted),
      isTrue,
    );
  });

  test('Tự tải lại danh sách chương khi vào lại màn hình', () async {
    final countingRepository = _CountingChapterRepository(buildChapters(10));
    final container = ProviderContainer(
      overrides: [
        chapterRepositoryProvider.overrideWithValue(countingRepository),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);

    final provider = chapterListViewModelProvider(seriesId);
    final firstSubscription = container.listen(provider, (_, _) {});
    await container.read(provider.future);
    expect(countingRepository.callCount, 1);

    firstSubscription.close();
    await Future<void>.delayed(Duration.zero);

    final secondSubscription = container.listen(provider, (_, _) {});
    addTearDown(secondSubscription.close);
    await container.read(provider.future);

    expect(countingRepository.callCount, 2);
  });

  testWidgets(
    'Hiển thị trạng thái Loading ban đầu trước khi dữ liệu hoàn tất',
    (tester) async {
      final fakeRepo = FakeChapterRepository(mockChapters);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [chapterRepositoryProvider.overrideWithValue(fakeRepo)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ChapterListScreen(
              seriesId: seriesId,
              seriesTitle: seriesTitle,
            ),
          ),
        ),
      );

      // Kiểm tra ngay khi chưa settle (đang loading)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}

class _CountingChapterRepository extends FakeChapterRepository {
  _CountingChapterRepository(super.chapters);

  int callCount = 0;

  @override
  Future<List<Chapter>> getChaptersBySeries(String seriesId) {
    callCount++;
    return super.getChaptersBySeries(seriesId);
  }
}
