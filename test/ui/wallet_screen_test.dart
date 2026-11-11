import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/config/environment.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/payment_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/auth_session.dart';
import 'package:joyleebook_mobile/domain/models/deposit_order.dart';
import 'package:joyleebook_mobile/domain/models/donation.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
import 'package:joyleebook_mobile/domain/models/wallet.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/wallet/widgets/wallet_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_payment_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

class _DelayedWalletRepo extends FakePaymentRepository {
  final Completer<Wallet> completer;

  _DelayedWalletRepo(this.completer);

  @override
  Future<Wallet> getWallet() => completer.future;
}

Widget _buildWalletApp(
  FakePaymentRepository paymentRepo, {
  FakeAuthRepository? authRepo,
  FakeSeriesRepository? seriesRepo,
  Future<bool> Function(Uri uri)? onLaunchUrl,
  Key? scopeKey,
}) {
  return ProviderScope(
    key: scopeKey,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        authRepo ?? FakeAuthRepository(savedSession: fakeSession),
      ),
      paymentRepositoryProvider.overrideWithValue(paymentRepo),
      if (seriesRepo != null)
        seriesRepositoryProvider.overrideWithValue(seriesRepo),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: WalletScreen(onLaunchUrl: onLaunchUrl),
    ),
  );
}

Future<void> _scrollToWidget(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Hiển thị trạng thái Loading khi đang tải ví', (tester) async {
    final completer = Completer<Wallet>();
    await tester.pumpWidget(
      _buildWalletApp(_DelayedWalletRepo(completer), scopeKey: UniqueKey()),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(Wallet(userId: 'user-1', balance: 5000));
    await tester.pumpAndSettle();
    expect(find.text('5.000 Xu'), findsOneWidget);
  });

  testWidgets('Hiển thị JoyleeEmptyState (401) khi chưa đăng nhập', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWalletApp(
        FakePaymentRepository(),
        authRepo: FakeAuthRepository(savedSession: null),
        scopeKey: UniqueKey(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Bạn chưa đăng nhập'), findsOneWidget);
  });

  testWidgets(
    'Hiển thị JoyleeErrorView khi lỗi mạng và khôi phục khi bấm Thử lại',
    (tester) async {
      final errorThenOkRepo = FakePaymentRepository(
        walletError: const AppException(
          message: 'Không thể kết nối tới PaymentService.',
        ),
        initialWallet: Wallet(userId: 'user-1', balance: 12000),
        initialTransactions: [
          PaymentTransaction(
            id: 'tx-old',
            orderCode: 1001,
            amountVnd: 50000,
            coins: 5000,
            status: DepositStatus.success,
            createdAt: DateTime(2026, 5, 1),
          ),
        ],
      );
      await tester.pumpWidget(_buildWalletApp(errorThenOkRepo));
      await tester.pumpAndSettle();

      expect(find.byType(JoyleeErrorView), findsOneWidget);
      expect(
        find.text('Không thể kết nối tới PaymentService.'),
        findsOneWidget,
      );

      errorThenOkRepo.walletError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('12.000 Xu'), findsOneWidget);
      await _scrollToWidget(tester, find.text('Đơn #1001'));
      expect(find.text('Đơn #1001'), findsOneWidget);
      expect(find.text('+5.000 Xu'), findsOneWidget);
    },
  );

  testWidgets('Kiểm tra biên số tiền nạp, tạo QR, mở PayOS và hủy đơn nạp', (
    tester,
  ) async {
    final launchedUris = <Uri>[];
    final repo = FakePaymentRepository(
      initialWallet: Wallet(userId: 'user-1', balance: 3000),
    );

    await tester.pumpWidget(
      _buildWalletApp(
        repo,
        onLaunchUrl: (uri) async {
          launchedUris.add(uri);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    // Nhập < 10.000 -> hiện lỗi validation, không gọi API
    await tester.enterText(find.byType(TextField), '5000');
    await tester.pump();
    expect(find.text('Số tiền nạp tối thiểu là 10.000 VNĐ.'), findsOneWidget);

    await _scrollToWidget(tester, find.text('Tạo mã QR thanh toán'));
    await tester.tap(find.text('Tạo mã QR thanh toán'));
    await tester.pump();
    expect(repo.createDepositCalls, 0);

    // Chọn preset 100.000 đ -> tạo QR thành công
    await _scrollToWidget(tester, find.text('100.000 đ'));
    await tester.tap(find.text('100.000 đ'));
    await tester.pump();
    expect(find.text('+10.000 Xu'), findsOneWidget);

    await _scrollToWidget(tester, find.text('Tạo mã QR thanh toán'));
    await tester.tap(find.text('Tạo mã QR thanh toán'));
    await tester.pumpAndSettle();

    expect(repo.createDepositCalls, 1);
    expect(repo.lastCreatedDepositAmount, 100000);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Mở trang thanh toán PayOS'), findsOneWidget);

    // Ẩn SnackBar tránh che nút khi cuộn
    ScaffoldMessenger.of(tester.element(find.byType(WalletScreen)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    // Mở PayOS -> nhận đúng checkoutUrl
    await _scrollToWidget(tester, find.text('Mở trang thanh toán PayOS'));
    await tester.tap(find.text('Mở trang thanh toán PayOS'));
    await tester.pump();
    expect(launchedUris, hasLength(1));
    expect(
      launchedUris.single.toString(),
      contains('https://pay.payos.vn/web/'),
    );

    // Kiểm tra thanh toán khi PayOS đã xác nhận -> cập nhật số dư
    repo.completeDepositOrder(20260501);
    await _scrollToWidget(tester, find.text('Kiểm tra thanh toán'));
    await tester.tap(find.text('Kiểm tra thanh toán'));
    await tester.pumpAndSettle();

    expect(find.text('Nạp Xu thành công!'), findsOneWidget);
    expect(find.text('13.000 Xu'), findsOneWidget);

    // Quay lại nạp thêm -> tạo đơn mới -> Hủy đơn với dialog xác nhận
    await tester.tap(find.text('Nạp thêm Xu'));
    await tester.pumpAndSettle();

    await _scrollToWidget(tester, find.text('Tạo mã QR thanh toán'));
    await tester.tap(find.text('Tạo mã QR thanh toán'));
    await tester.pumpAndSettle();

    ScaffoldMessenger.of(tester.element(find.byType(WalletScreen)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    await _scrollToWidget(tester, find.text('Hủy đơn'));
    await tester.tap(find.text('Hủy đơn'));
    await tester.pumpAndSettle();
    expect(find.text('Hủy đơn nạp tiền?'), findsOneWidget);

    await tester.tap(find.text('Hủy đơn').last);
    await tester.pumpAndSettle();
    expect(repo.cancelDepositCalls, 1);
    expect(find.text('Đã hủy đơn nạp tiền thành công.'), findsOneWidget);
  });

  testWidgets('Fallback sang Web Portal khi cổng PayOS trả về 503', (
    tester,
  ) async {
    final launchedUris = <Uri>[];
    final repo = FakePaymentRepository(
      createDepositError: const AppException(
        message: 'Cổng thanh toán PayOS đang tạm bảo trì.',
        statusCode: 503,
      ),
    );

    await tester.pumpWidget(
      _buildWalletApp(
        repo,
        onLaunchUrl: (uri) async {
          launchedUris.add(uri);
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToWidget(tester, find.text('Tạo mã QR thanh toán'));
    await tester.tap(find.text('Tạo mã QR thanh toán'));
    await tester.pumpAndSettle();

    expect(
      find.text('Cổng thanh toán PayOS đang tạm bảo trì.'),
      findsOneWidget,
    );
    await _scrollToWidget(tester, find.text('Nạp xu qua Web Portal'));
    expect(find.text('Nạp xu qua Web Portal'), findsOneWidget);

    await tester.tap(find.text('Nạp xu qua Web Portal'));
    await tester.pump();
    expect(launchedUris.single.toString(), Environment.walletWebUrl);
  });

  testWidgets('Không tràn RenderFlex trên màn hình hẹp 360x640', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = FakePaymentRepository(
      initialWallet: Wallet(userId: 'user-1', balance: 250000),
      initialTransactions: [
        PaymentTransaction(
          id: 'tx-1',
          orderCode: 998877,
          amountVnd: 100000,
          coins: 10000,
          status: DepositStatus.pending,
          createdAt: DateTime(2026, 5, 1),
        ),
      ],
    );

    await tester.pumpWidget(_buildWalletApp(repo));
    await tester.pumpAndSettle();

    await _scrollToWidget(tester, find.text('Tạo mã QR thanh toán'));
    await tester.tap(find.text('Tạo mã QR thanh toán'));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Unmount Widget tree để đóng polling timer sạch sẽ trước khi test kết thúc
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Role Reader không hiển thị tab hay mục Lịch sử được ủng hộ', (
    tester,
  ) async {
    await tester.pumpWidget(_buildWalletApp(FakePaymentRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Được ủng hộ'), findsNothing);
    expect(find.text('Lịch sử được ủng hộ'), findsNothing);
  });

  testWidgets(
    'Role Author chia 2 tab Nạp Xu & Được ủng hộ, tổng Xu và cho phép Thử lại khi lỗi',
    (tester) async {
      const authorSession = AuthSession(
        userId: 'author-1',
        username: 'tacgia.vn',
        role: UserRole.author,
      );
      final authorSeries = [
        const Series(
          id: 'story-1',
          title: 'Kiếm Lai',
          authorId: 'author-1',
          authorName: 'Tác Giả',
          description: 'Mô tả',
          coverImageUrl: '',
          status: SeriesStatus.ongoing,
        ),
        const Series(
          id: 'story-2',
          title: 'Phàm Nhân Tu Tiên',
          authorId: 'author-1',
          authorName: 'Tác Giả',
          description: 'Mô tả',
          coverImageUrl: '',
          status: SeriesStatus.completed,
        ),
      ];

      final paymentRepo = FakePaymentRepository(
        initialWallet: Wallet(userId: 'author-1', balance: 5000),
        storyDonationsError: const AppException(
          message: 'Không thể tải danh sách ủng hộ.',
        ),
        initialDonationsByStory: {
          'story-1': [
            StoryDonation(
              id: 'don-1',
              senderUserId: 'reader-a',
              coins: 200,
              message: 'Truyện hay quá tác giả ơi!',
              createdAt: DateTime(2026, 5, 2, 14, 0),
            ),
          ],
          'story-2': [
            StoryDonation(
              id: 'don-2',
              senderUserId: 'reader-b',
              coins: 150,
              createdAt: DateTime(2026, 5, 1, 9, 0),
            ),
          ],
        },
      );

      await tester.pumpWidget(
        _buildWalletApp(
          paymentRepo,
          authRepo: FakeAuthRepository(savedSession: authorSession),
          seriesRepo: FakeSeriesRepository(authorSeries),
        ),
      );
      await tester.pumpAndSettle();

      // Hiển thị 2 tab Nạp Xu & Được ủng hộ, Tab 1 hiển thị tổng số dư Xu hiện có
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Nạp Xu'), findsOneWidget);
      expect(find.text('Được ủng hộ'), findsOneWidget);
      expect(find.text('Số dư hiện tại'), findsOneWidget);
      expect(find.text('5.000 Xu'), findsOneWidget);
      expect(find.text('Nạp Xu vào ví'), findsOneWidget);

      // Chuyển sang tab Được ủng hộ
      await tester.tap(find.text('Được ủng hộ'));
      await tester.pumpAndSettle();

      expect(find.text('Tổng Xu đã nhận được'), findsOneWidget);
      expect(find.text('+0 Xu'), findsOneWidget);
      expect(find.text('Lịch sử được ủng hộ'), findsOneWidget);
      expect(find.text('Không thể tải danh sách ủng hộ.'), findsOneWidget);

      // Bấm Thử lại sau khi hết lỗi
      paymentRepo.storyDonationsError = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('+350 Xu'), findsOneWidget);
      expect(find.text('Từ 2 lượt ủng hộ của độc giả'), findsOneWidget);
      expect(find.text('Kiếm Lai'), findsOneWidget);
      expect(find.text('+200 Xu'), findsOneWidget);
      expect(find.text('"Truyện hay quá tác giả ơi!"'), findsOneWidget);
      await _scrollToWidget(tester, find.text('Phàm Nhân Tu Tiên'));
      expect(find.text('Phàm Nhân Tu Tiên'), findsOneWidget);
      expect(find.text('+150 Xu'), findsOneWidget);
    },
  );

  testWidgets('Role Author không tràn RenderFlex trên màn hình hẹp 360x640', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const authorSession = AuthSession(
      userId: 'author-1',
      username: 'tacgia.vn',
      role: UserRole.author,
    );
    final paymentRepo = FakePaymentRepository(
      initialWallet: Wallet(userId: 'author-1', balance: 1000),
      initialDonationsByStory: {
        'story-1': [
          StoryDonation(
            id: 'don-1',
            senderUserId: 'reader-a',
            coins: 500,
            message: 'Chúc tác giả ra chương đều mỗi ngày!',
            createdAt: DateTime(2026, 5, 2, 14, 0),
          ),
        ],
      },
    );

    await tester.pumpWidget(
      _buildWalletApp(
        paymentRepo,
        authRepo: FakeAuthRepository(savedSession: authorSession),
        seriesRepo: FakeSeriesRepository([
          const Series(
            id: 'story-1',
            title: 'Bộ Truyện Dài Kỳ Của Tác Giả Trên Màn Hình Nhỏ',
            authorId: 'author-1',
            authorName: 'Tác Giả',
            description: 'Mô tả',
            coverImageUrl: '',
            status: SeriesStatus.ongoing,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Được ủng hộ'));
    await tester.pumpAndSettle();

    expect(find.text('Tổng Xu đã nhận được'), findsOneWidget);
    expect(find.text('Lịch sử được ủng hộ'), findsOneWidget);
    expect(find.text('+500 Xu'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
