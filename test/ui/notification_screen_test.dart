import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/notification_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/app_notification.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/notifications/widgets/notification_item.dart';
import 'package:joyleebook_mobile/ui/notifications/widgets/notification_screen.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_notification_repository.dart';

AppNotification _notification({
  required String id,
  required String title,
  bool isRead = false,
  String message = 'Nội dung thông báo',
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    userId: fakeSession.userId,
    type: 0,
    title: title,
    message: message,
    readAt: isRead ? DateTime.now() : null,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: createdAt ?? DateTime.now(),
  );
}

Widget _buildScreen({
  required FakeNotificationRepository repository,
  FakeAuthRepository? auth,
}) {
  return ProviderScope(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repository),
      authRepositoryProvider.overrideWithValue(
        auth ?? FakeAuthRepository(savedSession: fakeSession),
      ),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const NotificationScreen()),
  );
}

void main() {
  testWidgets('Hiển thị danh sách thông báo và số lượng chưa đọc', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repo = FakeNotificationRepository(
      items: [
        _notification(id: 'n1', title: 'Chương 12 vừa phát hành'),
        _notification(id: 'n2', title: 'Chào mừng bạn mới', isRead: true),
      ],
    );

    await tester.pumpWidget(_buildScreen(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('1 chưa đọc'), findsOneWidget);
    expect(find.text('Chương 12 vừa phát hành'), findsOneWidget);
    expect(find.text('Chào mừng bạn mới'), findsOneWidget);
    expect(find.byType(NotificationItem), findsNWidgets(2));
    expect(find.bySemanticsLabel(RegExp('Chưa đọc')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Đã đọc')), findsOneWidget);
    expect(repo.getCallCount, 1);
    semantics.dispose();
  });

  testWidgets('Bấm vào thông báo chưa đọc sẽ gọi markSeen', (tester) async {
    final repo = FakeNotificationRepository(
      items: [_notification(id: 'n1', title: 'Chương 12 vừa phát hành')],
    );

    await tester.pumpWidget(_buildScreen(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('1 chưa đọc'), findsOneWidget);

    await tester.tap(find.text('Chương 12 vừa phát hành'));
    await tester.pumpAndSettle();

    expect(repo.markSeenCallCount, 1);
    expect(repo.markedSeenIds, contains('n1'));
    // Sau khi đọc xong không còn text "chưa đọc"
    expect(find.text('1 chưa đọc'), findsNothing);
  });

  testWidgets('Hiển thị JoyleeEmptyState khi không có thông báo', (
    tester,
  ) async {
    final repo = FakeNotificationRepository(items: []);

    await tester.pumpWidget(_buildScreen(repository: repo));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Chưa có thông báo'), findsOneWidget);
  });

  testWidgets('Lỗi mạng hiển thị JoyleeErrorView và Thử lại', (tester) async {
    final repo = FakeNotificationRepository()
      ..error = const AppException(message: 'Không thể kết nối đến máy chủ.');

    await tester.pumpWidget(_buildScreen(repository: repo));
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeErrorView), findsOneWidget);
    expect(find.text('Không thể kết nối đến máy chủ.'), findsOneWidget);

    repo.error = null;
    repo.items = [_notification(id: 'n1', title: 'Thông báo thành công')];

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Thông báo thành công'), findsOneWidget);
  });

  testWidgets('Chưa đăng nhập hiển thị JoyleeEmptyState nhắc đăng nhập', (
    tester,
  ) async {
    final repo = FakeNotificationRepository();

    await tester.pumpWidget(
      _buildScreen(repository: repo, auth: FakeAuthRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Chưa đăng nhập'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(repo.getCallCount, 0);
  });

  testWidgets('Kéo để làm mới (Pull-to-refresh) kích hoạt refresh', (
    tester,
  ) async {
    final repo = FakeNotificationRepository(
      items: [_notification(id: 'n1', title: 'Thông báo ban đầu')],
    );

    await tester.pumpWidget(_buildScreen(repository: repo));
    await tester.pumpAndSettle();

    expect(repo.getCallCount, 1);

    // Kéo danh sách xuống
    await tester.fling(
      find.byType(NotificationItem),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(repo.getCallCount, 2);
  });
}
