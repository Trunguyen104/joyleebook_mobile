import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/domain/models/chapter.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/chapter_item.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/chapter_list_screen.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/resume_reading_bar.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';

import '../../testing/fakes/fake_chapter_repository.dart';

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
        overrides: [
          chapterRepositoryProvider.overrideWithValue(fakeRepo),
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
          overrides: [
            chapterRepositoryProvider.overrideWithValue(fakeRepo),
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
          overrides: [
            chapterRepositoryProvider.overrideWithValue(fakeRepo),
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

  testWidgets(
    'Hiển thị trạng thái Loading ban đầu trước khi dữ liệu hoàn tất',
    (tester) async {
      final fakeRepo = FakeChapterRepository(mockChapters);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chapterRepositoryProvider.overrideWithValue(fakeRepo),
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

      // Kiểm tra ngay khi chưa settle (đang loading)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
}
