import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/chapter.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/chapter_detail_screen.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/chapter_item.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_detail_screen.dart';

import '../../testing/fakes/fake_chapter_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

void main() {
  const mockSeries = Series(
    id: 's1',
    title: 'Hành Trình Về Phương Đông',
    authorName: 'Nguyên Phong',
    description: 'Tác phẩm kinh điển về tâm linh và văn hóa phương Đông...',
    coverImageUrl: '',
    status: SeriesStatus.completed,
    genres: ['Tâm Linh', 'Triết Học'],
    isBookmarked: false,
    totalChapters: 2,
  );

  final mockChapters = [
    const Chapter(
      id: 'c1',
      seriesId: 's1',
      sortOrder: 1,
      title: 'Một người huyền bí',
      isFree: true,
      durationMinutes: 15,
    ),
    const Chapter(
      id: 'c2',
      seriesId: 's1',
      sortOrder: 2,
      title: 'Hội thảo khoa học',
      isFree: true,
      durationMinutes: 18,
    ),
  ];

  testWidgets(
    'Hiển thị đầy đủ thông tin chi tiết tác phẩm (tiêu đề, tác giả, trạng thái, thể loại, mô tả)',
    (tester) async {
      final fakeSeriesRepo = FakeSeriesRepository([mockSeries]);
      final fakeChapterRepo = FakeChapterRepository(mockChapters);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(fakeSeriesRepo),
            chapterRepositoryProvider.overrideWithValue(fakeChapterRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SeriesDetailScreen(seriesId: 's1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề và tác giả
      expect(find.text('Hành Trình Về Phương Đông'), findsAtLeast(1));
      expect(find.text('Nguyên Phong'), findsOneWidget);

      // Kiểm tra trạng thái và thể loại
      expect(find.text('Hoàn thành'), findsOneWidget);
      expect(find.text('Tâm Linh'), findsOneWidget);
      expect(find.text('Triết Học'), findsOneWidget);

      // Kiểm tra giới thiệu
      expect(find.text('Giới thiệu nội dung'), findsOneWidget);
      expect(
        find.text('Tác phẩm kinh điển về tâm linh và văn hóa phương Đông...'),
        findsOneWidget,
      );

      // Kiểm tra danh sách chương
      expect(find.byType(ChapterItem), findsNWidgets(2));
      expect(find.text('Ch. 1: Một người huyền bí'), findsOneWidget);
      expect(find.text('Ch. 2: Hội thảo khoa học'), findsOneWidget);
    },
  );

  testWidgets(
    'Bấm nút Bookmark thực hiện Optimistic UI chuyển đổi trạng thái',
    (tester) async {
      final fakeSeriesRepo = FakeSeriesRepository([mockSeries]);
      final fakeChapterRepo = FakeChapterRepository(mockChapters);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(fakeSeriesRepo),
            chapterRepositoryProvider.overrideWithValue(fakeChapterRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SeriesDetailScreen(initialSeries: mockSeries),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ban đầu: nút ghi "Lưu tủ sách"
      expect(find.text('Lưu tủ sách'), findsOneWidget);

      // Bấm nút Lưu tủ sách
      await tester.tap(find.text('Lưu tủ sách'));
      await tester.pump(); // Optimistic UI kích hoạt ngay lập tức

      // Kiểm tra nhãn đổi sang "Đã lưu"
      expect(find.text('Đã lưu'), findsOneWidget);

      // Đợi hoàn thành async và kiểm tra SnackBar thông báo thành công
      await tester.pumpAndSettle();
      expect(
        find.text('Đã thêm "Hành Trình Về Phương Đông" vào tủ sách cá nhân.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Hiển thị JoyleeErrorView khi tải chi tiết tác phẩm thất bại và hỗ trợ nút Thử lại',
    (tester) async {
      final fakeSeriesRepo = FakeSeriesRepository([], true); // Báo lỗi

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(fakeSeriesRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SeriesDetailScreen(seriesId: 'not_exist'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra màn hình lỗi và nút Thử lại
      expect(find.byType(JoyleeErrorView), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );

  testWidgets(
    'Bấm nút Đọc ngay mở ChapterDetailScreen của chương đầu tiên',
    (tester) async {
      final fakeSeriesRepo = FakeSeriesRepository([mockSeries]);
      final fakeChapterRepo = FakeChapterRepository(mockChapters);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(fakeSeriesRepo),
            chapterRepositoryProvider.overrideWithValue(fakeChapterRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SeriesDetailScreen(initialSeries: mockSeries),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Bấm nút "Đọc ngay"
      expect(find.text('Đọc ngay'), findsOneWidget);
      await tester.tap(find.text('Đọc ngay'));
      await tester.pumpAndSettle();

      // Xác nhận chuyển sang ChapterDetailScreen
      expect(find.byType(ChapterDetailScreen), findsOneWidget);
    },
  );
}
