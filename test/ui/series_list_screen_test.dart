import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/routing/app_paths.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_list_screen.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

void main() {
  testWidgets('Hiển thị JoyleeEmptyState khi danh sách truyện rỗng', (
    tester,
  ) async {
    // 1. Khởi tạo Fake Repository rỗng
    final fakeRepo = FakeSeriesRepository([]);

    // 2. Bọc Widget trong ProviderScope và ghi đè (override) seriesRepositoryProvider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SeriesListScreen(),
        ),
      ),
    );

    // 3. Đợi cho tất cả hiệu ứng và bất đồng bộ hoàn thành
    await tester.pumpAndSettle();

    // 4. Kiểm tra xem Empty State có xuất hiện trên màn hình hay không
    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Không tìm thấy truyện nào'), findsOneWidget);
  });

  testWidgets('Hiển thị danh sách truyện khi có dữ liệu từ Repository', (
    tester,
  ) async {
    // 1. Khởi tạo Fake Repository có 1 truyện mẫu
    final mockData = [
      const Series(
        id: '1',
        title: 'Bí Mật Cổ Trấn Giữa Sương Mù',
        authorName: 'Nguyên Phong',
        description: 'Chuyến hành trình khám phá bí ẩn...',
        coverImageUrl: '',
        status: SeriesStatus.ongoing,
        genres: ['Phiêu Lưu'],
      ),
    ];
    final fakeRepo = FakeSeriesRepository(mockData);

    // 2. Chạy widget với dữ liệu giả lập
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SeriesListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 3. Xác nhận tên truyện, tác giả và badge thể loại viết hoa
    expect(find.text('Bí Mật Cổ Trấn Giữa Sương Mù'), findsWidgets);
    expect(find.text('Nguyên Phong'), findsWidgets);
    expect(find.text('Phiêu Lưu'), findsOneWidget);
  });

  testWidgets('Hiển thị tối đa 2 badge thể loại và viết hoa chữ cái đầu', (
    tester,
  ) async {
    final mockData = [
      const Series(
        id: '2',
        title: 'Thần Thoại Phương Đông',
        authorName: 'Tác Giả A',
        description: 'Mô tả truyện...',
        coverImageUrl: '',
        status: SeriesStatus.ongoing,
        genres: ['tiên hiệp', 'huyền huyễn', 'khoa học'],
      ),
    ];
    final fakeRepo = FakeSeriesRepository(mockData);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SeriesListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 2 thể loại đầu tiên được hiển thị và viết hoa
    expect(find.text('Tiên Hiệp'), findsOneWidget);
    expect(find.text('Huyền Huyễn'), findsOneWidget);
    // Xác nhận Text có cấu hình ellipsis khi quá dài
    final textWidget = tester.widget<Text>(find.text('Tiên Hiệp'));
    expect(textWidget.overflow, TextOverflow.ellipsis);
    expect(textWidget.maxLines, 1);

    // Thể loại thứ 3 không được hiển thị
    expect(find.text('Khoa Học'), findsNothing);
    expect(find.text('khoa học'), findsNothing);
  });

  testWidgets('Header hiển thị đúng tiêu đề và nút Tìm kiếm', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(FakeSeriesRepository([])),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(savedSession: fakeSession),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SeriesListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kho Truyện JoyleeBook'), findsOneWidget);
    expect(find.byTooltip('Tìm kiếm & Khám phá'), findsOneWidget);
  });

  testWidgets(
    'Mỗi section trên Home giới hạn tối đa 10 truyện và nút Xem thêm sang Khám phá',
    (tester) async {
      final manySeries = List.generate(
        15,
        (i) => Series(
          id: 's-${i + 1}',
          title: 'Truyện Mẫu ${i + 1}',
          authorName: 'Tác Giả',
          description: 'Mô tả',
          coverImageUrl: '',
          status: SeriesStatus.ongoing,
        ),
      );
      final router = GoRouter(
        initialLocation: AppPaths.series,
        routes: [
          GoRoute(
            path: AppPaths.series,
            builder: (_, _) => const SeriesListScreen(),
          ),
          GoRoute(
            path: AppPaths.search,
            builder: (_, _) => const Scaffold(body: Text('Trang Khám Phá')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(
              FakeSeriesRepository(manySeries),
            ),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra các ListView cuộn ngang trong các section có itemCount = 10
      // (ListView.separated tạo 10 * 2 - 1 = 19 children gồm card + separator, chứ không phải 15 * 2 - 1 = 29)
      await tester.scrollUntilVisible(
        find.text('Thử đọc Truyện Mới'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final horizontalLists = tester
          .widgetList<ListView>(find.byType(ListView))
          .where((lv) => lv.scrollDirection == Axis.horizontal)
          .toList();
      final standardSectionLists = horizontalLists
          .where((lv) => lv.childrenDelegate.estimatedChildCount == 19)
          .toList();
      expect(standardSectionLists, isNotEmpty);
      expect(
        horizontalLists.any(
          (lv) => lv.childrenDelegate.estimatedChildCount == 29,
        ),
        isFalse,
      );

      // Bấm "Xem thêm" chuyển sang tab Khám phá
      expect(find.text('Xem thêm'), findsAtLeastNWidgets(1));
      await tester.ensureVisible(find.text('Xem thêm').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem thêm').last);
      await tester.pumpAndSettle();
      expect(find.text('Trang Khám Phá'), findsOneWidget);
    },
  );
}
