import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/data/services/google_sign_in_service.dart';
import 'package:joyleebook_mobile/ui/auth/view_models/sign_in_view_model.dart';
import 'package:joyleebook_mobile/ui/auth/view_models/auth_session_view_model.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/sign_in_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_google_sign_in_service.dart';

late ProviderContainer _container;

Future<void> _pumpScreen(
  WidgetTester tester,
  FakeAuthRepository fake, {
  FakeGoogleSignInService? google,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fake),
        googleSignInServiceProvider.overrideWithValue(
          google ?? FakeGoogleSignInService(),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          _container = ProviderScope.containerOf(context);
          return MaterialApp(theme: AppTheme.light, home: const SignInScreen());
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillForm(
  WidgetTester tester,
  String username,
  String password,
) async {
  await tester.enterText(find.byType(TextField).at(0), username);
  await tester.enterText(find.byType(TextField).at(1), password);
}

final _submitButton = find.widgetWithText(JoyleeButton, 'Đăng nhập');

void main() {
  final googleButton = find.byType(OutlinedButton);

  Future<void> tapGoogle(WidgetTester tester) async {
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
  }

  testWidgets('Google đăng nhập không cần nhập mật khẩu và lưu phiên', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);
    await tapGoogle(tester);
    await tester.pumpAndSettle();

    expect(fake.googleSignInCallCount, 1);
    expect(fake.lastGoogleIdToken, 'google-id-token');
    expect(fake.signInCallCount, 0);
    expect(_container.read(authSessionProvider).value, fakeSession);
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
  });

  testWidgets('Hủy chọn Google không gọi API, không báo lỗi và mở lại được', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    final google = FakeGoogleSignInService(idToken: null);
    await _pumpScreen(tester, fake, google: google);
    await tapGoogle(tester);
    await tester.pumpAndSettle();

    expect(fake.googleSignInCallCount, 0);
    expect(_container.read(signInViewModelProvider).isLoading, isFalse);
    expect(find.byType(SnackBar), findsNothing);
    expect(_container.read(authSessionProvider).value, isNull);
    await tapGoogle(tester);
    await tester.pumpAndSettle();
    expect(google.callCount, 2);
  });

  testWidgets('Lỗi SDK Google hiện thông báo và không gọi gateway', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(
      tester,
      fake,
      google: FakeGoogleSignInService(
        error: const AppException(
          message: 'Không thể đăng nhập Google. Vui lòng thử lại.',
        ),
      ),
    );
    await tapGoogle(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Không thể đăng nhập Google. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(fake.googleSignInCallCount, 0);
    expect(_container.read(signInViewModelProvider).isLoading, isFalse);
  });

  testWidgets(
    'Gateway từ chối Google thì không tạo phiên và cho phép thử lại',
    (tester) async {
      final fake = FakeAuthRepository(
        error: const AppException(
          message: 'Không thể xác minh tài khoản Google.',
        ),
      );
      await _pumpScreen(tester, fake);
      await tapGoogle(tester);
      await tester.pumpAndSettle();
      expect(find.text('Không thể xác minh tài khoản Google.'), findsOneWidget);
      expect(_container.read(authSessionProvider).value, isNull);
      fake.error = null;
      await tapGoogle(tester);
      await tester.pumpAndSettle();
      expect(fake.googleSignInCallCount, 2);
      expect(_container.read(authSessionProvider).value, fakeSession);
    },
  );

  testWidgets('Đang chọn Google thì khóa cả hai cách đăng nhập', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    final google = FakeGoogleSignInService();
    await _pumpScreen(tester, fake, google: google);
    await tapGoogle(tester);
    await tester.pump();
    expect(tester.widget<OutlinedButton>(googleButton).onPressed, isNull);
    expect(
      tester.widget<JoyleeButton>(find.byType(JoyleeButton)).onPressed,
      isNull,
    );
    expect(
      await _container
          .read(signInViewModelProvider.notifier)
          .signInWithGoogle(),
      isFalse,
    );
    expect(
      await _container
          .read(signInViewModelProvider.notifier)
          .submit(username: 'abc', password: '123'),
      isFalse,
    );
    await tester.pumpAndSettle();
    expect(google.callCount, 1);
    expect(fake.googleSignInCallCount, 1);
    expect(fake.signInCallCount, 0);
  });

  testWidgets('Màn hình nhỏ có bàn phím vẫn cuộn tới nút Google', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.reset);
    await _pumpScreen(tester, FakeAuthRepository());
    await tester.ensureVisible(googleButton);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bỏ trống thì báo lỗi dưới từng ô và không gọi API', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);

    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tên đăng nhập hoặc email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(fake.signInCallCount, 0);
  });

  testWidgets('Đăng nhập thành công thì lưu phiên và báo thành công', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);

    await _fillForm(tester, 'phuc123', 'matkhau123');
    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(fake.signInCallCount, 1);
    expect(_container.read(authSessionProvider).value, fakeSession);
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
  });

  testWidgets('Sai mật khẩu (401) thì hiện SnackBar thân thiện', (
    tester,
  ) async {
    final fake = FakeAuthRepository(
      error: const AppException(
        message: 'Tên đăng nhập hoặc mật khẩu không đúng.',
        statusCode: 401,
      ),
    );
    await _pumpScreen(tester, fake);

    await _fillForm(tester, 'phuc123', 'saimatkhau1');
    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Tên đăng nhập hoặc mật khẩu không đúng.'),
      findsOneWidget,
    );
    expect(_container.read(authSessionProvider).value, isNull);
  });

  testWidgets('Đang gửi thì khóa nút, bấm liên tục chỉ gọi API 1 lần', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);

    await _fillForm(tester, 'phuc123', 'matkhau123');
    await tester.tap(_submitButton);
    await tester.pump(); // request đang chạy (fake trễ 50ms)

    // Lúc này nút chỉ hiện vòng xoay (không còn chữ) nên tìm theo kiểu widget
    final button = tester.widget<JoyleeButton>(find.byType(JoyleeButton));
    expect(button.isLoading, isTrue);
    expect(button.onPressed, isNull);
    expect(tester.widget<OutlinedButton>(googleButton).onPressed, isNull);
    expect(
      await _container
          .read(signInViewModelProvider.notifier)
          .signInWithGoogle(),
      isFalse,
    );

    await tester.tap(find.byType(JoyleeButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(fake.signInCallCount, 1);
  });

  testWidgets('Hiển thị liên kết Quên mật khẩu trên màn hình đăng nhập', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);

    expect(find.text('Quên mật khẩu?'), findsOneWidget);
  });

  testWidgets(
    'Hiển thị AppBar với tiêu đề "Đăng nhập / Đăng ký" và nút quay về thay vì nút Để sau',
    (tester) async {
      final fake = FakeAuthRepository();
      await _pumpScreen(tester, fake);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Đăng nhập / Đăng ký'), findsOneWidget);
      expect(find.byTooltip('Quay về'), findsOneWidget);
      expect(find.text('Để sau'), findsNothing);
    },
  );

  testWidgets('Hiển thị nội dung gợi ý (placeholder/hintText) trong ô nhập', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);

    expect(find.text('Nhập tên đăng nhập hoặc email'), findsOneWidget);
    expect(find.text('Nhập mật khẩu'), findsOneWidget);
  });
}
