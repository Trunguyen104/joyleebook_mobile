import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/ui/auth/view_models/auth_session_view_model.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/sign_in_screen.dart';
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
