import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/ui/auth/view_models/auth_session_view_model.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/sign_up_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';

import '../../testing/fakes/fake_auth_repository.dart';

late ProviderContainer _container;

Future<void> _pumpScreen(WidgetTester tester, FakeAuthRepository fake) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
      child: Consumer(
        builder: (context, ref, _) {
          _container = ProviderScope.containerOf(context);
          return MaterialApp(theme: AppTheme.light, home: const SignUpScreen());
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _submit(
  WidgetTester tester, {
  required String username,
  required String password,
  required String confirmPassword,
}) async {
  await tester.enterText(find.byType(TextField).at(0), username);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.enterText(find.byType(TextField).at(2), confirmPassword);
  final submitButton = find.widgetWithText(JoyleeButton, 'Đăng ký');
  // Form đăng ký dài hơn màn hình test (600px) -> cuộn tới nút trước khi bấm
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Dữ liệu sai thì báo lỗi đúng từng ô và không gọi API', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);

    await _submit(
      tester,
      username: 'ab',
      password: 'chicochu',
      confirmPassword: 'khac',
    );

    expect(
      find.text('Tên đăng nhập từ 3-64 ký tự và không chứa ký tự đặc biệt'),
      findsOneWidget,
    );
    expect(
      find.text('Mật khẩu tối thiểu 8 ký tự, bao gồm cả chữ và số'),
      findsOneWidget,
    );
    expect(find.text('Mật khẩu xác nhận không trùng khớp'), findsOneWidget);
    expect(fake.signUpCallCount, 0);
  });

  testWidgets('Tên đăng nhập đã tồn tại (409) thì báo dưới ô tên', (
    tester,
  ) async {
    final fake = FakeAuthRepository(
      error: const AppException(message: 'Trùng', statusCode: 409),
    );
    await _pumpScreen(tester, fake);

    await _submit(
      tester,
      username: 'phuc123',
      password: 'matkhau123',
      confirmPassword: 'matkhau123',
    );

    expect(fake.signUpCallCount, 1);
    expect(find.text('Tên đăng nhập này đã được sử dụng.'), findsOneWidget);
  });

  testWidgets('Đăng ký thành công thì được đăng nhập luôn', (tester) async {
    final fake = FakeAuthRepository();
    await _pumpScreen(tester, fake);

    await _submit(
      tester,
      username: 'phuc.reader_01',
      password: 'matkhau123',
      confirmPassword: 'matkhau123',
    );

    expect(fake.signUpCallCount, 1);
    expect(_container.read(authSessionProvider).value, fakeSession);
    expect(find.text('Đăng ký thành công. Chào mừng bạn!'), findsOneWidget);
  });
}
