import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/routing/app_paths.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/reset_password_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';

import '../../testing/fakes/fake_auth_repository.dart';

Future<void> _pump(WidgetTester tester, FakeAuthRepository fake) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ResetPasswordScreen(
          email: 'reader@example.com',
          token: 'reset-token',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  final button = find.widgetWithText(JoyleeButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _fillPasswords(
  WidgetTester tester,
  String password,
  String confirm,
) async {
  await tester.enterText(find.byType(TextField).at(0), password);
  await tester.enterText(find.byType(TextField).at(1), confirm);
}

void main() {
  testWidgets('Liên kết có mã hóa lỗi không làm văng màn hình', (tester) async {
    final fake = FakeAuthRepository();
    await _pump(tester, fake);
    await tester.enterText(
      find.byType(TextField).at(1),
      'https://example.com/reset-password?token=%FF',
    );
    await _tap(tester, 'Tiếp tục');
    expect(
      find.textContaining('Liên kết khôi phục không đúng định dạng'),
      findsOneWidget,
    );
    expect(fake.validateResetTokenCallCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dán liên kết khôi phục giữ nguyên mã có ký tự đặc biệt', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pump(tester, fake);
    final link = Uri.https('reader.example.com', '/reset-password', {
      'email': 'linked@example.com',
      'token': 'code+with/slash==',
    });
    await tester.enterText(find.byType(TextField).at(1), link.toString());
    await _tap(tester, 'Tiếp tục');
    await _fillPasswords(tester, 'newPassword123', 'newPassword123');
    await _tap(tester, 'Đặt lại mật khẩu');
    expect(fake.lastResetEmail, 'linked@example.com');
    expect(fake.lastResetToken, 'code+with/slash==');
  });

  testWidgets('Lỗi kiểm tra mã cho phép thử lại', (tester) async {
    final fake = FakeAuthRepository(
      error: const AppException(message: 'Mất kết nối mạng.'),
    );
    await _pump(tester, fake);
    await _tap(tester, 'Tiếp tục');
    expect(find.text('Mất kết nối mạng.'), findsOneWidget);
    fake.error = null;
    await _tap(tester, 'Tiếp tục');
    expect(find.text('Mật khẩu mới'), findsOneWidget);
    expect(fake.validateResetTokenCallCount, 2);
  });

  testWidgets('Email và mã trống không gọi API kiểm tra', (tester) async {
    final fake = FakeAuthRepository();
    await _pump(tester, fake);
    await tester.enterText(find.byType(TextField).at(0), '');
    await tester.enterText(find.byType(TextField).at(1), '');
    await _tap(tester, 'Tiếp tục');
    expect(find.text('Vui lòng nhập địa chỉ email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mã khôi phục trong email'), findsOneWidget);
    expect(fake.validateResetTokenCallCount, 0);
  });

  testWidgets('Mã hết hạn không cho nhập mật khẩu mới', (tester) async {
    final fake = FakeAuthRepository()..isTokenValid = false;
    await _pump(tester, fake);
    await _tap(tester, 'Tiếp tục');
    expect(find.textContaining('Mã khôi phục không hợp lệ'), findsOneWidget);
    expect(find.text('Mật khẩu mới'), findsNothing);
    expect(fake.resetPasswordCallCount, 0);
  });

  testWidgets('Chặn mật khẩu yếu và xác nhận không khớp', (tester) async {
    final fake = FakeAuthRepository();
    await _pump(tester, fake);
    await _tap(tester, 'Tiếp tục');
    await _fillPasswords(tester, 'short', 'different');
    await _tap(tester, 'Đặt lại mật khẩu');
    expect(
      find.text('Mật khẩu tối thiểu 8 ký tự, bao gồm cả chữ và số'),
      findsOneWidget,
    );
    expect(find.text('Mật khẩu xác nhận không trùng khớp'), findsOneWidget);
    expect(fake.resetPasswordCallCount, 0);
  });

  testWidgets('Đặt lại thành công gửi đúng dữ liệu và không tự đăng nhập', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pump(tester, fake);
    await _tap(tester, 'Tiếp tục');
    await _fillPasswords(tester, 'newPassword123', 'newPassword123');
    await _tap(tester, 'Đặt lại mật khẩu');
    expect(fake.lastResetEmail, 'reader@example.com');
    expect(fake.lastResetToken, 'reset-token');
    expect(fake.lastResetPassword, 'newPassword123');
    expect(fake.lastResetConfirmPassword, 'newPassword123');
    expect(find.text('Đã đặt lại mật khẩu'), findsOneWidget);
    expect(fake.savedSession, isNull);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Chặn gửi lặp bằng nút và bàn phím khi đang chờ', (tester) async {
    final fake = FakeAuthRepository();
    await _pump(tester, fake);
    await _tap(tester, 'Tiếp tục');
    await _fillPasswords(tester, 'newPassword123', 'newPassword123');
    final button = find.widgetWithText(JoyleeButton, 'Đặt lại mật khẩu');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(
      tester.widget<JoyleeButton>(find.byType(JoyleeButton)).onPressed,
      isNull,
    );
    tester.widget<TextField>(find.byType(TextField).last).onSubmitted!(
      'newPassword123',
    );
    await tester.pumpAndSettle();
    expect(fake.resetPasswordCallCount, 1);
  });

  testWidgets('Lỗi mạng cho phép gửi lại mật khẩu', (tester) async {
    final fake = FakeAuthRepository();
    await _pump(tester, fake);
    await _tap(tester, 'Tiếp tục');
    fake.error = const AppException(message: 'Không thể kết nối đến máy chủ.');
    await _fillPasswords(tester, 'newPassword123', 'newPassword123');
    await _tap(tester, 'Đặt lại mật khẩu');
    expect(find.text('Không thể kết nối đến máy chủ.'), findsOneWidget);
    expect(find.text('Mật khẩu mới'), findsOneWidget);
    fake.error = null;
    await _tap(tester, 'Đặt lại mật khẩu');
    expect(find.text('Đã đặt lại mật khẩu'), findsOneWidget);
  });

  testWidgets('Mã hết hạn trong lúc nhập yêu cầu kiểm tra lại mã', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pump(tester, fake);
    await _tap(tester, 'Tiếp tục');
    fake.error = const AppException(message: 'Mã hết hạn', statusCode: 400);
    await _fillPasswords(tester, 'newPassword123', 'newPassword123');
    await _tap(tester, 'Đặt lại mật khẩu');
    expect(find.text('Mã khôi phục'), findsOneWidget);
    expect(
      find.textContaining('Vui lòng kiểm tra mã khôi phục'),
      findsOneWidget,
    );
    expect(find.text('Mật khẩu mới'), findsNothing);
  });

  testWidgets('Rời trang khi đang kiểm tra mã không cập nhật provider đã hủy', (
    tester,
  ) async {
    await _pump(tester, FakeAuthRepository());
    await tester.tap(find.widgetWithText(JoyleeButton, 'Tiếp tục'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Màn hình nhỏ có bàn phím vẫn cuộn và gửi được', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);
    await _pump(tester, FakeAuthRepository());
    await _tap(tester, 'Tiếp tục');
    await _fillPasswords(tester, 'newPassword123', 'newPassword123');
    await _tap(tester, 'Đặt lại mật khẩu');
    expect(tester.takeException(), isNull);
    expect(find.text('Đã đặt lại mật khẩu'), findsOneWidget);
  });

  testWidgets('Thành công quay về đăng nhập giữ đích đến ban đầu', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppPaths.resetPassword,
      routes: [
        GoRoute(
          path: AppPaths.resetPassword,
          builder: (_, _) => const ResetPasswordScreen(
            email: 'reader@example.com',
            token: 'token',
            from: AppPaths.bookmarks,
          ),
        ),
        GoRoute(
          path: AppPaths.signIn,
          builder: (_, state) => Scaffold(
            body: Text('Đăng nhập: ${state.uri.queryParameters['from']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await _tap(tester, 'Tiếp tục');
    await _fillPasswords(tester, 'newPassword123', 'newPassword123');
    await _tap(tester, 'Đặt lại mật khẩu');
    await _tap(tester, 'Quay lại Đăng nhập');
    expect(find.text('Đăng nhập: /bookmarks'), findsOneWidget);
  });
}
