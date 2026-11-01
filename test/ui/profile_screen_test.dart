import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/profile_screen.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_profile_repository.dart';

const _profile = UserProfile(
  id: '115a1ebc-2cb0-41e5-9690-7166fc73b753',
  username: 'phuc123',
  displayName: 'Phúc',
  bio: 'Mê truyện trinh thám.',
  role: UserRole.author,
  stats: ReadingStats(
    seriesStarted: 12,
    chaptersCompleted: 87,
    currentStreakDays: 3,
    longestStreakDays: 9,
    periodDays: 30,
    chaptersCompletedInPeriod: 21,
    activeDaysInPeriod: 14,
  ),
);

// Mặc định đã đăng nhập; truyền FakeAuthRepository() để giả lập chưa đăng nhập
Widget _buildApp(FakeProfileRepository fake, {FakeAuthRepository? auth}) =>
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(fake),
        authRepositoryProvider.overrideWithValue(
          auth ?? FakeAuthRepository(savedSession: fakeSession),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const ProfileScreen()),
    );

void main() {
  testWidgets('Hiển thị hồ sơ và thống kê đọc khi có dữ liệu', (tester) async {
    // Bật cây semantics để tìm theo nhãn của trình đọc màn hình
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _buildApp(FakeProfileRepository(profile: _profile)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Phúc'), findsOneWidget);
    expect(find.text('@phuc123'), findsOneWidget);
    expect(find.text('Tác giả'), findsOneWidget);
    expect(find.text('Mê truyện trinh thám.'), findsOneWidget);
    expect(find.bySemanticsLabel('Truyện đã đọc: 12'), findsOneWidget);
    expect(find.bySemanticsLabel('Chuỗi dài nhất: 9 ngày'), findsOneWidget);
    expect(find.text('30 NGÀY QUA'), findsOneWidget);
    expect(find.text('Đọc xong 21 chương trong kỳ'), findsOneWidget);
    expect(find.text('Bạn chưa đọc chương nào'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Lỗi 401 hiển thị JoyleeEmptyState gợi ý đăng nhập', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        FakeProfileRepository(
          error: const AppException(message: 'Chưa đăng nhập', statusCode: 401),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Bạn chưa đăng nhập'), findsOneWidget);
  });

  testWidgets('Lỗi mạng hiển thị JoyleeErrorView, bấm Thử lại thì tải lại', (
    tester,
  ) async {
    final fake = FakeProfileRepository(
      error: const AppException(message: 'Không thể kết nối tới máy chủ.'),
    );
    await tester.pumpWidget(_buildApp(fake));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeErrorView), findsOneWidget);
    // retry: null trong provider -> Riverpod không tự thử lại ngầm
    expect(fake.callCount, 1);

    fake
      ..error = null
      ..profile = _profile;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(fake.callCount, 2);
    expect(find.text('Phúc'), findsOneWidget);
  });

  testWidgets('Chưa đăng nhập thì không gọi API hồ sơ, hiện gợi ý đăng nhập', (
    tester,
  ) async {
    final fake = FakeProfileRepository(profile: _profile);
    await tester.pumpWidget(_buildApp(fake, auth: FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa đăng nhập'), findsOneWidget);
    expect(fake.callCount, 0);
    // Chưa đăng nhập thì không có nút đăng xuất
    expect(find.byTooltip('Đăng xuất'), findsNothing);
  });

  testWidgets('Đăng xuất: hỏi xác nhận, bấm Hủy thì vẫn giữ phiên', (
    tester,
  ) async {
    final auth = FakeAuthRepository(savedSession: fakeSession);
    await tester.pumpWidget(
      _buildApp(FakeProfileRepository(profile: _profile), auth: auth),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Đăng xuất'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(auth.signOutCallCount, 0);
    expect(find.text('Phúc'), findsOneWidget);
  });

  testWidgets('Đăng xuất: xác nhận thì xóa phiên và hiện gợi ý đăng nhập', (
    tester,
  ) async {
    final auth = FakeAuthRepository(savedSession: fakeSession);
    await tester.pumpWidget(
      _buildApp(FakeProfileRepository(profile: _profile), auth: auth),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(JoyleeButton, 'Đăng xuất'));
    await tester.pumpAndSettle();

    expect(auth.signOutCallCount, 1);
    expect(find.text('Đã đăng xuất'), findsOneWidget);
    expect(find.text('Bạn chưa đăng nhập'), findsOneWidget);
  });
}
