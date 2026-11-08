import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/ui/auth/view_models/auth_session_view_model.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/change_password_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';

import '../../testing/fakes/fake_auth_repository.dart';

Future<void> _pump(WidgetTester tester, FakeAuthRepository fake) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ChangePasswordScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fill(
  WidgetTester tester,
  String current,
  String password,
  String confirm,
) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), current);
  await tester.enterText(fields.at(1), password);
  await tester.enterText(fields.at(2), confirm);
}

Future<void> _submit(WidgetTester tester) async {
  final button = find.byType(JoyleeButton);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Form trống không gọi API', (tester) async {
    final fake = FakeAuthRepository(savedSession: fakeSession);
    await _pump(tester, fake);
    await _submit(tester);
    expect(find.text('Vui lòng nhập mật khẩu hiện tại'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(fake.changePasswordCallCount, 0);
  });

  testWidgets('Chặn mật khẩu mới trùng mật khẩu cũ và xác nhận không khớp', (
    tester,
  ) async {
    final fake = FakeAuthRepository(savedSession: fakeSession);
    await _pump(tester, fake);
    await _fill(tester, 'password123', 'password123', 'different123');
    await _submit(tester);
    expect(
      find.text('Mật khẩu mới phải khác mật khẩu hiện tại'),
      findsOneWidget,
    );
    expect(find.text('Mật khẩu xác nhận không trùng khớp'), findsOneWidget);
    expect(fake.changePasswordCallCount, 0);
  });

  testWidgets('Sai mật khẩu hiện tại giữ phiên và cho phép sửa để thử lại', (
    tester,
  ) async {
    final fake = FakeAuthRepository(
      savedSession: fakeSession,
      error: const AppException(
        message: 'Mật khẩu hiện tại không đúng.',
        statusCode: 400,
      ),
    );
    await _pump(tester, fake);
    await _fill(tester, 'wrongPassword1', 'newPassword123', 'newPassword123');
    await _submit(tester);
    expect(find.text('Mật khẩu hiện tại không đúng.'), findsOneWidget);
    expect(fake.savedSession, fakeSession);
    fake.error = null;
    await _submit(tester);
    expect(fake.changePasswordCallCount, 2);
    expect(fake.savedSession, isNull);
  });

  testWidgets('Thành công gửi nguyên mật khẩu và xóa phiên trong ứng dụng', (
    tester,
  ) async {
    final fake = FakeAuthRepository(savedSession: fakeSession);
    await _pump(tester, fake);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChangePasswordScreen)),
    );
    await container.read(authSessionProvider.future);
    await _fill(
      tester,
      ' oldPassword123 ',
      ' newPassword123 ',
      ' newPassword123 ',
    );
    await _submit(tester);
    expect(fake.lastCurrentPassword, ' oldPassword123 ');
    expect(fake.lastNewPassword, ' newPassword123 ');
    expect(fake.lastConfirmNewPassword, ' newPassword123 ');
    expect(container.read(authSessionProvider).value, isNull);
    expect(find.textContaining('Đổi mật khẩu thành công.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      isEmpty,
    );
  });

  testWidgets('Khóa nút và chặn bàn phím gửi lặp khi đang chờ', (tester) async {
    final fake = FakeAuthRepository(savedSession: fakeSession);
    await _pump(tester, fake);
    await _fill(tester, 'oldPassword123', 'newPassword123', 'newPassword123');
    await tester.ensureVisible(find.byType(JoyleeButton));
    await tester.tap(find.byType(JoyleeButton));
    await tester.pump();
    expect(
      tester.widget<JoyleeButton>(find.byType(JoyleeButton)).onPressed,
      isNull,
    );
    tester.widget<TextField>(find.byType(TextField).last).onSubmitted!(
      'newPassword123',
    );
    await tester.pumpAndSettle();
    expect(fake.changePasswordCallCount, 1);
  });

  testWidgets('Màn hình nhỏ có bàn phím không tràn nội dung', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.reset);
    await _pump(tester, FakeAuthRepository(savedSession: fakeSession));
    await _fill(tester, 'oldPassword123', 'newPassword123', 'newPassword123');
    await _submit(tester);
    expect(tester.takeException(), isNull);
  });
}
