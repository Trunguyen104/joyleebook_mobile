import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/forgot_password_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';

import '../../testing/fakes/fake_auth_repository.dart';

Future<void> _pumpScreen(
  WidgetTester tester,
  FakeAuthRepository fake, {
  String? from,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: ForgotPasswordScreen(from: from),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _submitButton = find.widgetWithText(JoyleeButton, 'Gửi liên kết đặt lại');

void main() {
  testWidgets('Bỏ trống email thì báo lỗi dưới ô và không gọi API', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);

    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập địa chỉ email'), findsOneWidget);
    expect(fake.forgotPasswordCallCount, 0);
  });

  testWidgets('Email sai định dạng thì báo lỗi và không gọi API', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);

    await tester.enterText(find.byType(TextField), 'invalid-email');
    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Địa chỉ email không đúng định dạng'), findsOneWidget);
    expect(fake.forgotPasswordCallCount, 0);
  });

  testWidgets(
    'Gửi yêu cầu thành công: gọi API và hiển thị màn hình xác nhận với email đã nhập',
    (tester) async {
      final fake = FakeAuthRepository();
      await _pumpScreen(tester, fake);

      await tester.enterText(find.byType(TextField), 'reader@joyleebook.com');
      await tester.tap(_submitButton);
      await tester.pumpAndSettle();

      expect(fake.forgotPasswordCallCount, 1);
      expect(fake.lastForgotPasswordEmail, 'reader@joyleebook.com');

      // Chuyển sang giao diện thông báo thành công
      expect(find.text('Đã gửi liên kết đặt lại'), findsOneWidget);
      expect(find.textContaining('reader@joyleebook.com'), findsOneWidget);
      expect(
        find.widgetWithText(JoyleeButton, 'Quay lại Đăng nhập'),
        findsOneWidget,
      );
      expect(find.text('Thử địa chỉ email khác'), findsOneWidget);
    },
  );

  testWidgets(
    'Màn hình thành công: bấm Thử địa chỉ email khác quay lại form nhập',
    (tester) async {
      final fake = FakeAuthRepository();
      await _pumpScreen(tester, fake);

      await tester.enterText(find.byType(TextField), 'reader@joyleebook.com');
      await tester.tap(_submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Đã gửi liên kết đặt lại'), findsOneWidget);

      // Cuộn tới và bấm "Thử địa chỉ email khác"
      final retryButton = find.text('Thử địa chỉ email khác');
      await tester.ensureVisible(retryButton);
      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      // Quay lại màn hình form nhập ban đầu
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(
        find.widgetWithText(JoyleeButton, 'Gửi liên kết đặt lại'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Lỗi máy chủ / mạng thì hiển thị SnackBar thông báo', (
    tester,
  ) async {
    final fake = FakeAuthRepository(
      error: const AppException(message: 'Không thể kết nối đến máy chủ.'),
    );
    await _pumpScreen(tester, fake);

    await tester.enterText(find.byType(TextField), 'reader@joyleebook.com');
    await tester.tap(_submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Không thể kết nối đến máy chủ.'), findsOneWidget);
    // Vẫn ở màn hình form nhập
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
  });

  testWidgets('Đang gửi thì khóa nút và chống bấm liên tục', (tester) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);

    await tester.enterText(find.byType(TextField), 'reader@joyleebook.com');
    await tester.tap(_submitButton);

    // Bơm 1 frame (chưa xong 50ms delay) -> kiểm tra trạng thái loading
    await tester.pump();
    final button = tester.widget<JoyleeButton>(find.byType(JoyleeButton));
    expect(button.isLoading, isTrue);
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Bấm lần thứ hai khi đang loading
    await tester.tap(find.byType(JoyleeButton), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Chỉ gọi API đúng 1 lần
    expect(fake.forgotPasswordCallCount, 1);
  });
}
