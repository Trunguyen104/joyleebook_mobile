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
import 'package:joyleebook_mobile/ui/core/widgets/joylee_notification_bell.dart';
import 'package:joyleebook_mobile/ui/notifications/widgets/notification_bell_button.dart';
import 'package:joyleebook_mobile/ui/notifications/widgets/notification_popup.dart';

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

Widget _buildBell({
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
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(actions: const [NotificationBellButton()]),
        body: const SizedBox.expand(),
      ),
    ),
  );
}

Future<void> _openPopup(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.byType(NotificationBellButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Không hiện loading rồi hiển thị danh sách thông báo trong popup',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = FakeNotificationRepository(
        items: [
          _notification(id: 'n1', title: 'Chương mới'),
          _notification(id: 'n2', title: 'Thông báo hệ thống', isRead: true),
        ],
      );

      await tester.pumpWidget(_buildBell(repository: repo));
      await tester.pump();
      await tester.tap(find.byType(NotificationBellButton));
      await tester.pump();

      expect(find.byType(NotificationPopup), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpAndSettle();

      expect(find.text('Chương mới'), findsOneWidget);
      expect(find.text('Nội dung thông báo'), findsNWidgets(2));
      expect(find.bySemanticsLabel(RegExp('Chưa đọc')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Đã đọc')), findsOneWidget);
      expect(repo.getCallCount, 1);

      await tester.tap(find.byTooltip('Đóng thông báo'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPopup), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('Popup rỗng hiển thị JoyleeEmptyState', (tester) async {
    await tester.pumpWidget(
      _buildBell(repository: FakeNotificationRepository()),
    );
    await _openPopup(tester);

    expect(find.byType(NotificationPopup), findsOneWidget);
    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Chưa có thông báo'), findsOneWidget);
  });

  testWidgets(
    'Lỗi tải thông báo hiển thị JoyleeErrorView, bấm Thử lại thì tải lại',
    (tester) async {
      final repo = FakeNotificationRepository(
        items: [_notification(id: 'n1', title: 'Chương mới')],
      );
      repo.error = const AppException(
        message: 'Không thể kết nối tới máy chủ.',
      );

      await tester.pumpWidget(_buildBell(repository: repo));
      await _openPopup(tester);

      expect(find.byType(JoyleeErrorView), findsOneWidget);
      expect(repo.getCallCount, 1);

      repo.error = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(repo.getCallCount, 2);
      expect(find.text('Chương mới'), findsOneWidget);
    },
  );

  testWidgets('Bấm thông báo chưa đọc gọi markSeen và đổi sang Đã đọc', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repo = FakeNotificationRepository(
      items: [_notification(id: 'n1', title: 'Chương mới')],
    );

    await tester.pumpWidget(_buildBell(repository: repo));
    await _openPopup(tester);

    await tester.tap(find.text('Chương mới'));
    await tester.pumpAndSettle();

    expect(repo.markSeenCallCount, 1);
    expect(repo.markedSeenIds, ['n1']);
    expect(find.bySemanticsLabel(RegExp('Đã đọc')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('markSeen lỗi thì rollback trạng thái và hiện SnackBar', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repo = FakeNotificationRepository(
      items: [_notification(id: 'n1', title: 'Chương mới')],
    )..markSeenError = const AppException(message: 'Lỗi máy chủ.');

    await tester.pumpWidget(_buildBell(repository: repo));
    await _openPopup(tester);

    await tester.tap(find.text('Chương mới'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp('Chưa đọc')), findsOneWidget);
    expect(
      find.text('Không thể đánh dấu đã đọc. Đã hoàn tác trạng thái.'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('Chưa đăng nhập thì không hiện chuông và không gọi API', (
    tester,
  ) async {
    final repo = FakeNotificationRepository(
      items: [_notification(id: 'n1', title: 'Chương mới')],
    );

    await tester.pumpWidget(
      _buildBell(repository: repo, auth: FakeAuthRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Thông báo'), findsNothing);
    expect(repo.getCallCount, 0);
  });

  testWidgets('Popup không tràn khỏi màn hình nhỏ', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = FakeNotificationRepository(
      items: [_notification(id: 'n1', title: 'Chương mới')],
    );

    await tester.pumpWidget(_buildBell(repository: repo));
    await _openPopup(tester);

    final popupRect = tester.getRect(find.byType(NotificationPopup));
    expect(popupRect.left, greaterThanOrEqualTo(0));
    expect(popupRect.right, lessThanOrEqualTo(320));
    expect(popupRect.bottom, lessThanOrEqualTo(568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chuông thông báo hiển thị badge 99+ khi chưa đọc nhiều', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: AppBar(
            actions: [
              JoyleeNotificationBell(unreadCount: 150, onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.text('99+'), findsOneWidget);
    expect(find.byTooltip('Thông báo, 150 chưa đọc'), findsOneWidget);
  });
}
