import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
import 'package:joyleebook_mobile/routing/app_paths.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/settings_screen.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_profile_repository.dart';

const _profile = UserProfile(
  id: 'user-1',
  username: 'phuc123',
  displayName: 'Phúc',
  bio: 'Mê truyện trinh thám.',
  role: UserRole.reader,
);

Widget _buildSettingsApp({
  FakeAuthRepository? auth,
  FakeProfileRepository? profile,
}) {
  final router = GoRouter(
    initialLocation: AppPaths.settings,
    routes: [
      GoRoute(
        path: AppPaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppPaths.editProfile,
        builder: (context, state) =>
            const Scaffold(body: Text('Trang Edit Profile')),
      ),
      GoRoute(
        path: AppPaths.changePassword,
        builder: (context, state) =>
            const Scaffold(body: Text('Trang Change Password')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        auth ?? FakeAuthRepository(savedSession: fakeSession),
      ),
      profileRepositoryProvider.overrideWithValue(
        profile ?? FakeProfileRepository(profile: _profile),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('Hiển thị đầy đủ các mục trong Cài đặt khi đã đăng nhập', (
    tester,
  ) async {
    await tester.pumpWidget(_buildSettingsApp());
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('TÀI KHOẢN'), findsOneWidget);
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    expect(find.text('Đổi mật khẩu'), findsOneWidget);
    expect(find.text('GIAO DIỆN & TRẢI NGHIỆM'), findsOneWidget);
    expect(find.text('Chế độ hiển thị'), findsOneWidget);
    expect(find.text('Sáng'), findsOneWidget);
    expect(find.text('Tối'), findsOneWidget);
    expect(find.text('Hệ thống'), findsOneWidget);
    expect(find.text('PHIÊN ĐĂNG NHẬP'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
    expect(find.text('JoyleeBook Mobile'), findsOneWidget);
  });

  testWidgets('Bấm Chỉnh sửa hồ sơ điều hướng đúng route', (tester) async {
    await tester.pumpWidget(_buildSettingsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chỉnh sửa hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('Trang Edit Profile'), findsOneWidget);
  });

  testWidgets('Bấm Đổi mật khẩu điều hướng đúng route', (tester) async {
    await tester.pumpWidget(_buildSettingsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.text('Trang Change Password'), findsOneWidget);
  });

  testWidgets('Chuyển đổi giao diện Sáng / Tối / Hệ thống', (tester) async {
    await tester.pumpWidget(_buildSettingsApp());
    await tester.pumpAndSettle();

    final darkSegment = find.text('Tối');
    expect(darkSegment, findsOneWidget);
    await tester.tap(darkSegment);
    await tester.pumpAndSettle();

    final lightSegment = find.text('Sáng');
    await tester.tap(lightSegment);
    await tester.pumpAndSettle();
  });

  testWidgets('Đăng xuất: bấm Hủy thì không đăng xuất', (tester) async {
    final fakeAuth = FakeAuthRepository(savedSession: fakeSession);
    await tester.pumpWidget(_buildSettingsApp(auth: fakeAuth));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(fakeAuth.signOutCallCount, 0);
  });

  testWidgets('Đăng xuất: bấm xác nhận thì gọi signOut', (tester) async {
    final fakeAuth = FakeAuthRepository(savedSession: fakeSession);
    await tester.pumpWidget(_buildSettingsApp(auth: fakeAuth));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(JoyleeButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(fakeAuth.signOutCallCount, 1);
  });

  testWidgets('Khi chưa đăng nhập: hiển thị Đăng nhập / Đăng ký', (
    tester,
  ) async {
    final fakeAuth = FakeAuthRepository(); // chưa đăng nhập
    await tester.pumpWidget(_buildSettingsApp(auth: fakeAuth));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập / Đăng ký'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsNothing);
    // Vẫn hiển thị phần đổi giao diện
    expect(find.text('Chế độ hiển thị'), findsOneWidget);
  });
}
