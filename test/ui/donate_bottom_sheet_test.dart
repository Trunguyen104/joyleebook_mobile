import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/data/repositories/payment_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/domain/models/wallet.dart';
import 'package:joyleebook_mobile/routing/app_paths.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/donation/widgets/donate_bottom_sheet.dart';
import 'package:joyleebook_mobile/ui/donation/widgets/story_donations_section.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_detail_screen.dart';
import 'package:joyleebook_mobile/ui/wallet/widgets/wallet_screen.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_chapter_repository.dart';
import '../../testing/fakes/fake_payment_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

void main() {
  const otherAuthorSeries = Series(
    id: 'story-donate-1',
    title: 'Kiếm Lai',
    authorId: 'author-999',
    authorName: 'Phong Hỏa',
    description: 'Bộ truyện tiên hiệp đặc sắc.',
    coverImageUrl: '',
    status: SeriesStatus.ongoing,
    totalChapters: 0,
  );

  final ownAuthorSeries = Series(
    id: 'story-own-1',
    title: 'Truyện Tự Sáng Tác',
    authorId: fakeSession.userId,
    authorName: 'Chính Tôi',
    description: 'Tác phẩm của chính mình.',
    coverImageUrl: '',
    status: SeriesStatus.ongoing,
    totalChapters: 0,
  );

  Widget buildSeriesRouterApp({
    required Series series,
    required FakePaymentRepository paymentRepo,
    FakeAuthRepository? authRepo,
  }) {
    final router = GoRouter(
      initialLocation: AppPaths.seriesDetail(series.id),
      routes: [
        GoRoute(
          path: AppPaths.seriesDetail(':id'),
          builder: (_, state) =>
              SeriesDetailScreen(seriesId: state.pathParameters['id']!),
        ),
        GoRoute(path: AppPaths.wallet, builder: (_, _) => const WalletScreen()),
        GoRoute(
          path: AppPaths.signIn,
          builder: (_, _) => const Scaffold(body: Text('Màn hình Đăng nhập')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        seriesRepositoryProvider.overrideWithValue(
          FakeSeriesRepository([series]),
        ),
        chapterRepositoryProvider.overrideWithValue(FakeChapterRepository([])),
        authRepositoryProvider.overrideWithValue(
          authRepo ?? FakeAuthRepository(savedSession: fakeSession),
        ),
        paymentRepositoryProvider.overrideWithValue(paymentRepo),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  testWidgets(
    'Chưa đăng nhập khi bấm Tặng xu sẽ hiện dialog yêu cầu đăng nhập',
    (tester) async {
      await tester.pumpWidget(
        buildSeriesRouterApp(
          series: otherAuthorSeries,
          paymentRepo: FakePaymentRepository(),
          authRepo: FakeAuthRepository(savedSession: null),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Tặng xu cho tác giả'));
      await tester.pumpAndSettle();

      expect(find.text('Đăng nhập để tặng xu'), findsOneWidget);
      expect(find.text('Đăng nhập ngay'), findsOneWidget);
    },
  );

  testWidgets('Chặn tự tặng xu cho truyện của chính mình bằng SnackBar', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSeriesRouterApp(
        series: ownAuthorSeries,
        paymentRepo: FakePaymentRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tặng xu cho tác giả'));
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn không thể tự ủng hộ truyện của chính mình.'),
      findsOneWidget,
    );
    expect(find.byType(DonateBottomSheet), findsNothing);
  });

  testWidgets(
    'Kiểm tra biên số xu, cảnh báo thiếu số dư và điều hướng sang Ví Xu',
    (tester) async {
      final paymentRepo = FakePaymentRepository(
        initialWallet: Wallet(userId: fakeSession.userId, balance: 30),
      );
      await tester.pumpWidget(
        buildSeriesRouterApp(
          series: otherAuthorSeries,
          paymentRepo: paymentRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Tặng xu cho tác giả'));
      await tester.pumpAndSettle();

      expect(find.byType(DonateBottomSheet), findsOneWidget);
      expect(find.text('30 Xu'), findsOneWidget);

      // Mặc định chọn 50 Xu > số dư 30 Xu -> cảnh báo thiếu xu
      expect(
        find.text('Số dư ví (30 Xu) không đủ để tặng 50 Xu.'),
        findsOneWidget,
      );

      // Nhập < 10 Xu -> hiện lỗi validation
      await tester.enterText(
        find.widgetWithText(TextField, 'Số Xu muốn tặng'),
        '5',
      );
      await tester.pump();
      expect(find.text('Số xu ủng hộ tối thiểu là 10 Xu.'), findsOneWidget);

      // Bấm "Nạp thêm xu" -> điều hướng sang WalletScreen
      await tester.tap(find.text('Nạp thêm xu'));
      await tester.pumpAndSettle();
      expect(find.byType(WalletScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Tặng xu thành công cập nhật danh sách Độc giả ủng hộ và số dư ví',
    (tester) async {
      final paymentRepo = FakePaymentRepository(
        initialWallet: Wallet(userId: fakeSession.userId, balance: 500),
      );
      await tester.pumpWidget(
        buildSeriesRouterApp(
          series: otherAuthorSeries,
          paymentRepo: paymentRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StoryDonationsSection), findsOneWidget);
      expect(
        find.text(
          'Chưa có độc giả nào ủng hộ tác phẩm này.\nHãy là người đầu tiên gửi tặng Xu cho tác giả!',
        ),
        findsOneWidget,
      );

      // Cuộn xuống phần Độc giả ủng hộ rồi bấm nút Tặng xu
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tặng xu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tặng xu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('100 Xu'));
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Lời nhắn gửi tác giả (không bắt buộc)'),
        'Truyện hay quá tác giả ơi!',
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Tặng 100 Xu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tặng 100 Xu'));
      await tester.pumpAndSettle();

      expect(paymentRepo.donateCalls, 1);
      expect(paymentRepo.lastDonatedStoryId, otherAuthorSeries.id);
      expect(paymentRepo.lastDonatedCoins, 100);
      expect(paymentRepo.lastDonatedMessage, 'Truyện hay quá tác giả ơi!');
      expect(paymentRepo.wallet.balance, 400);

      expect(
        find.text('Đã tặng 100 Xu ủng hộ tác phẩm "Kiếm Lai"!'),
        findsOneWidget,
      );
      expect(find.text('"Truyện hay quá tác giả ơi!"'), findsOneWidget);
      expect(find.text('+100 Xu'), findsOneWidget);
    },
  );

  testWidgets(
    'DonateBottomSheet không tràn RenderFlex trên màn hình hẹp 360x640',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final paymentRepo = FakePaymentRepository(
        initialWallet: Wallet(userId: fakeSession.userId, balance: 20),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              FakeAuthRepository(savedSession: fakeSession),
            ),
            paymentRepositoryProvider.overrideWithValue(paymentRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => DonateBottomSheet.show(
                      context,
                      storyId: otherAuthorSeries.id,
                      storyTitle: otherAuthorSeries.title,
                    ),
                    child: const Text('Mở bảng tặng xu'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mở bảng tặng xu'));
      await tester.pumpAndSettle();

      expect(find.byType(DonateBottomSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
