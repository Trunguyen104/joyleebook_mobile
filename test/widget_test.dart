// Test toàn app: GoRouter + 4 tab + chuyển hướng đăng nhập.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/app.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/notification_repository.dart';
import 'package:joyleebook_mobile/data/repositories/payment_repository.dart';
import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/routing/app_router.dart';
import 'package:joyleebook_mobile/routing/app_paths.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/reset_password_screen.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/change_password_screen.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/notification_socket_client.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/sign_in_screen.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/sign_up_screen.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';
import 'package:joyleebook_mobile/ui/gateway_test/widgets/gateway_test_screen.dart';
import 'package:joyleebook_mobile/ui/notifications/widgets/notification_screen.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/edit_profile_screen.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/profile_screen.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/settings_screen.dart';

import '../testing/fakes/fake_auth_repository.dart';
import '../testing/fakes/fake_notification_repository.dart';
import '../testing/fakes/fake_notification_socket_client.dart';
import '../testing/fakes/fake_payment_repository.dart';
import '../testing/fakes/fake_profile_repository.dart';
import '../testing/fakes/fake_series_repository.dart';
import '../testing/fakes/fake_token_storage.dart';

ProviderScope _buildApp(
  FakeAuthRepository auth, {
  FakeProfileRepository? profiles,
}) => ProviderScope(
  overrides: [
    seriesRepositoryProvider.overrideWithValue(FakeSeriesRepository([])),
    profileRepositoryProvider.overrideWithValue(
      profiles ?? FakeProfileRepository(),
    ),
    authRepositoryProvider.overrideWithValue(auth),
    notificationRepositoryProvider.overrideWithValue(
      FakeNotificationRepository(),
    ),
    tokenStorageProvider.overrideWithValue(
      FakeTokenStorage(accessToken: 'test-access-token'),
    ),
    notificationSocketClientProvider.overrideWithValue(
      FakeNotificationSocketClient(),
    ),
    paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
  ],
  child: const JoyleeBookApp(),
);

void main() {
  testWidgets('Cá nhân → Đổi mật khẩu → thành công yêu cầu đăng nhập lại', (
    tester,
  ) async {
    final fake = FakeAuthRepository(savedSession: fakeSession);
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'oldPassword123');
    await tester.enterText(find.byType(TextField).at(1), 'newPassword123');
    await tester.enterText(find.byType(TextField).at(2), 'newPassword123');
    await tester.ensureVisible(
      find.widgetWithText(JoyleeButton, 'Đổi mật khẩu'),
    );
    await tester.tap(find.widgetWithText(JoyleeButton, 'Đổi mật khẩu'));
    await tester.pumpAndSettle();
    expect(fake.changePasswordCallCount, 1);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(
      tester.widget<SignInScreen>(find.byType(SignInScreen)).from,
      AppPaths.profile,
    );
    expect(find.textContaining('Đổi mật khẩu thành công.'), findsOneWidget);
  });

  testWidgets('Cá nhân → Chỉnh sửa hồ sơ mở form đúng dữ liệu', (tester) async {
    final fake = FakeAuthRepository(savedSession: fakeSession);
    await tester.pumpWidget(
      _buildApp(
        fake,
        profiles: FakeProfileRepository(
          profile: const UserProfile(
            id: 'user-1',
            username: 'phuc123',
            displayName: 'Phúc',
            role: UserRole.reader,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.tap(find.text('Chỉnh sửa hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsOneWidget);
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    expect(find.text('@phuc123'), findsOneWidget);
  });

  testWidgets('Chưa đăng nhập không truy cập trực tiếp trang đổi mật khẩu', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeAuthRepository()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(JoyleeBookApp)),
    );
    container.read(appRouterProvider).go(AppPaths.changePassword);
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('Chưa đăng nhập không truy cập trực tiếp trang chỉnh sửa hồ sơ', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeAuthRepository()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(JoyleeBookApp)),
    );
    container.read(appRouterProvider).go(AppPaths.editProfile);
    await tester.pumpAndSettle();

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(
      tester.widget<SignInScreen>(find.byType(SignInScreen)).from,
      AppPaths.editProfile,
    );
  });

  testWidgets('Quên mật khẩu từ Đăng nhập đến đặt lại giữ tham số from', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeAuthRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Quên mật khẩu?'));
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'reader@example.com');
    await tester.ensureVisible(find.text('Gửi liên kết đặt lại'));
    await tester.tap(find.text('Gửi liên kết đặt lại'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tôi đã có mã khôi phục'));
    await tester.tap(find.text('Tôi đã có mã khôi phục'));
    await tester.pumpAndSettle();
    final screen = tester.widget<ResetPasswordScreen>(
      find.byType(ResetPasswordScreen),
    );
    expect(screen.email, 'reader@example.com');
    expect(screen.from, AppPaths.profile);
  });

  testWidgets('Route đặt lại đọc email và token từ URL không cần extra', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeAuthRepository()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(JoyleeBookApp)),
    );
    container
        .read(appRouterProvider)
        .go(
          Uri(
            path: AppPaths.resetPassword,
            queryParameters: {
              'email': 'reader@example.com',
              'token': 'code+with/slash==',
            },
          ).toString(),
        );
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller!.text, 'reader@example.com');
    expect(fields[1].controller!.text, 'code+with/slash==');
  });

  testWidgets('JoyleeBookApp render và chuyển đổi tab thành công', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeAuthRepository()));
    await tester.pumpAndSettle();

    // Tab 0 mặc định là Kho Truyện (xem được khi chưa đăng nhập)
    expect(find.text('Kho Truyện JoyleeBook'), findsOneWidget);
    expect(find.text('Kho Truyện'), findsOneWidget);
    expect(find.text('Khám phá'), findsOneWidget);
    expect(find.text('Tủ sách'), findsOneWidget);
    expect(find.text('Cá nhân'), findsOneWidget);
    // Nút Thông báo và Kiểm tra Gateway không nằm trên thanh navbar đáy
    expect(find.text('Thông báo'), findsNothing);
    expect(find.text('Kiểm tra Gateway'), findsNothing);

    await tester.tap(find.text('Khám phá'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
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

  testWidgets(
    'Chưa đăng nhập: điều hướng sang Thông báo thì chuyển sang Đăng nhập',
    (tester) async {
      await tester.pumpWidget(_buildApp(FakeAuthRepository()));
      await tester.pumpAndSettle();

      final router = ProviderScope.containerOf(
        tester.element(find.byType(JoyleeBookApp)),
      ).read(appRouterProvider);
      router.go(AppPaths.notifications);
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(NotificationScreen), findsNothing);
    },
  );

  testWidgets(
    'Đã đăng nhập sẵn: điều hướng sang Thông báo mở màn hình Thông báo',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(FakeAuthRepository(savedSession: fakeSession)),
      );
      await tester.pumpAndSettle();

      final router = ProviderScope.containerOf(
        tester.element(find.byType(JoyleeBookApp)),
      ).read(appRouterProvider);
      router.go(AppPaths.notifications);
      await tester.pumpAndSettle();

      expect(find.byType(NotificationScreen), findsOneWidget);
      expect(find.text('Chưa có thông báo'), findsOneWidget);
    },
  );

  testWidgets('Cài đặt → Mở màn hình Kiểm tra Gateway thành công', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(FakeAuthRepository(savedSession: fakeSession)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cá nhân'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cài đặt'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Kiểm tra Gateway'));
    await tester.tap(find.text('Kiểm tra Gateway'));
    await tester.pumpAndSettle();

    expect(find.byType(GatewayTestScreen), findsOneWidget);
    expect(find.text('Kiểm tra Kết nối Gateway'), findsOneWidget);
    expect(find.text('Bắt đầu Kiểm tra Kết nối'), findsOneWidget);
  });
}
