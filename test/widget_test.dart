// Test toàn app: GoRouter + 4 tab + chuyển hướng đăng nhập.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/app.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/sign_in_screen.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/sign_up_screen.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/profile_screen.dart';

import '../testing/fakes/fake_auth_repository.dart';
import '../testing/fakes/fake_profile_repository.dart';
import '../testing/fakes/fake_series_repository.dart';

ProviderScope _buildApp(FakeAuthRepository auth) => ProviderScope(
  overrides: [
    seriesRepositoryProvider.overrideWithValue(FakeSeriesRepository([])),
    profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
    authRepositoryProvider.overrideWithValue(auth),
  ],
  child: const JoyleeBookApp(),
);

void main() {
  testWidgets('JoyleeBookApp render và chuyển đổi tab thành công', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeAuthRepository()));
    await tester.pumpAndSettle();

    // Tab 0 mặc định là Kho Truyện (xem được khi chưa đăng nhập)
    expect(find.text('Kho Truyện JoyleeBook'), findsOneWidget);
    expect(find.text('Kho Truyện'), findsOneWidget);
    expect(find.text('Tủ sách'), findsOneWidget);
    expect(find.text('Kiểm tra Gateway'), findsOneWidget);

    await tester.tap(find.text('Kiểm tra Gateway'));
    await tester.pumpAndSettle();

    expect(find.text('Kiểm tra Kết nối Gateway'), findsOneWidget);
    expect(find.text('Bắt đầu Kiểm tra Kết nối'), findsOneWidget);
  });

  testWidgets('Chưa đăng nhập: bấm tab Tủ sách thì chuyển sang Đăng nhập', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeAuthRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tủ sách'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('Chưa đăng nhập: bấm tab Cá nhân thì chuyển sang Đăng nhập', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeAuthRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('Đăng nhập xong thì tự quay về tab Cá nhân', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(_buildApp(auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'phuc123');
    await tester.enterText(find.byType(TextField).at(1), 'matkhau123');
    await tester.tap(find.widgetWithText(JoyleeButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(auth.signInCallCount, 1);
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
  });

  testWidgets('Từ Đăng nhập chuyển sang Đăng ký và quay lại', (tester) async {
    await tester.pumpWidget(_buildApp(FakeAuthRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    // Link nằm cuối form, cuộn tới trước khi bấm
    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.byType(SignUpScreen), findsOneWidget);

    await tester.ensureVisible(find.text('Đăng nhập'));
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('Đã đăng nhập sẵn thì vào thẳng tab Cá nhân', (tester) async {
    await tester.pumpWidget(
      _buildApp(FakeAuthRepository(savedSession: fakeSession)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(SignInScreen), findsNothing);
  });
}
