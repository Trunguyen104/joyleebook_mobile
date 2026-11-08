import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/app.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/data/repositories/notification_repository.dart';
import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/notification_socket_client.dart';
import 'package:joyleebook_mobile/domain/models/chapter.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/chapter_detail_screen.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/chapter_item.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_detail_screen.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_chapter_repository.dart';
import '../../testing/fakes/fake_notification_repository.dart';
import '../../testing/fakes/fake_notification_socket_client.dart';
import '../../testing/fakes/fake_profile_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';
import '../../testing/fakes/fake_token_storage.dart';

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

      // Kiểm tra trạng thái và thể loại ở Tab Tóm tắt
      expect(find.text('Hoàn thành'), findsOneWidget);
      expect(find.text('Tâm Linh'), findsOneWidget);
      expect(find.text('Triết Học'), findsOneWidget);

      // Kiểm tra giới thiệu
      expect(find.text('Giới thiệu nội dung'), findsOneWidget);
      expect(
        find.text('Tác phẩm kinh điển về tâm linh và văn hóa phương Đông...'),
        findsOneWidget,
      );

      // Chuyển sang Tab "Chương" để kiểm tra danh sách chương
      await tester.tap(find.text('Chương (2)'));
      await tester.pumpAndSettle();

      // Kiểm tra danh sách chương
      expect(find.byType(ChapterItem), findsNWidgets(2));
      expect(find.text('Ch. 1: Một người huyền bí'), findsOneWidget);
      expect(find.text('Ch. 2: Hội thảo khoa học'), findsOneWidget);
    },
  );

  testWidgets(
    'Tab Chương tự cập nhật tổng số khi series chưa có totalChapters',
    (tester) async {
      const seriesWithoutCount = Series(
        id: 's1',
        title: 'Hành Trình Về Phương Đông',
        authorName: 'Nguyên Phong',
        description: 'Tác phẩm kinh điển về tâm linh và văn hóa phương Đông...',
        coverImageUrl: '',
        status: SeriesStatus.completed,
        totalChapters: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(
              FakeSeriesRepository([seriesWithoutCount]),
            ),
            chapterRepositoryProvider.overrideWithValue(
              FakeChapterRepository(mockChapters),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SeriesDetailScreen(initialSeries: seriesWithoutCount),
          ),
        ),
      );

      // Đang tải: chưa biết tổng số chương nên không hiển thị "(0)".
      expect(find.text('Chương (0)'), findsNothing);
      expect(find.text('Chương'), findsOneWidget);

      await tester.pumpAndSettle();

      // Tải xong: nhãn tab tự cập nhật đúng tổng số chương đã có.
      expect(find.text('Chương (2)'), findsOneWidget);
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
    'Bấm nút Đọc ngay mở trang đọc chương đầu tiên (toàn màn hình, qua GoRouter)',
    (tester) async {
      final fakeSeriesRepo = FakeSeriesRepository([mockSeries]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(fakeSeriesRepo),
            chapterRepositoryProvider.overrideWithValue(
              FakeChapterRepository(mockChapters),
            ),
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(savedSession: fakeSession),
            ),
            notificationRepositoryProvider.overrideWithValue(
              FakeNotificationRepository(),
            ),
            tokenStorageProvider.overrideWithValue(
              FakeTokenStorage(accessToken: 'test-access-token'),
            ),
            notificationSocketClientProvider.overrideWithValue(
              FakeNotificationSocketClient(),
            ),
          ],
          child: const JoyleeBookApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Kho Truyện -> bấm vào truyện -> mở chi tiết, vẫn thấy thanh tab
      await tester.tap(find.text(mockSeries.title));
      await tester.pumpAndSettle();
      expect(find.byType(SeriesDetailScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      // Bấm nút "Đọc ngay"
      expect(find.text('Đọc ngay'), findsOneWidget);
      await tester.tap(find.text('Đọc ngay'));
      await tester.pumpAndSettle();

      // Trang đọc mở toàn màn hình: không còn thanh tab
      expect(find.byType(ChapterDetailScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        fakeSeriesRepo.readingProgressUpdateCount,
        greaterThanOrEqualTo(1),
      );

      // Sang chương sau: trang đọc được THAY THẾ, không chồng thêm trang mới
      await tester.tap(find.text('Chương sau'));
      await tester.pumpAndSettle();
      expect(find.byType(ChapterDetailScreen), findsOneWidget);
      expect(
        fakeSeriesRepo.readingProgressUpdateCount,
        greaterThanOrEqualTo(2),
      );

      // Back 1 lần -> về thẳng chi tiết truyện
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ChapterDetailScreen), findsNothing);
      expect(find.byType(SeriesDetailScreen), findsOneWidget);
    },
  );
}
