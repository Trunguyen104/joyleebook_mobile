import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/notification_repository.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/notification_socket_client.dart';
import 'package:joyleebook_mobile/domain/models/app_notification.dart';
import 'package:joyleebook_mobile/ui/auth/view_models/auth_session_view_model.dart';
import 'package:joyleebook_mobile/ui/core/services/app_messenger.dart';
import 'package:joyleebook_mobile/ui/notifications/view_models/notification_feed_view_model.dart';
import 'package:joyleebook_mobile/ui/notifications/view_models/notification_realtime_view_model.dart';
import 'package:joyleebook_mobile/ui/notifications/widgets/notification_realtime_listener.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_notification_repository.dart';
import '../../testing/fakes/fake_notification_socket_client.dart';
import '../../testing/fakes/fake_token_storage.dart';

AppNotification _notification({String id = 'realtime-1'}) {
  return AppNotification(
    id: id,
    userId: fakeSession.userId,
    type: 0,
    title: '📖 Chương mới vừa ra mắt!',
    message: 'Truyện bạn đang đọc vừa có chương mới.',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

ProviderContainer _container({
  FakeAuthRepository? auth,
  FakeNotificationSocketClient? socket,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        auth ?? FakeAuthRepository(savedSession: fakeSession),
      ),
      notificationRepositoryProvider.overrideWithValue(
        FakeNotificationRepository(),
      ),
      tokenStorageProvider.overrideWithValue(
        FakeTokenStorage(accessToken: 'test-access-token'),
      ),
      notificationSocketClientProvider.overrideWithValue(
        socket ?? FakeNotificationSocketClient(),
      ),
    ],
  );
}

Widget _buildWidget(FakeNotificationSocketClient socket) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(savedSession: fakeSession),
      ),
      notificationRepositoryProvider.overrideWithValue(
        FakeNotificationRepository(),
      ),
      tokenStorageProvider.overrideWithValue(
        FakeTokenStorage(accessToken: 'test-access-token'),
      ),
      notificationSocketClientProvider.overrideWithValue(socket),
    ],
    child: NotificationRealtimeListener(
      child: MaterialApp(
        scaffoldMessengerKey: appScaffoldMessengerKey,
        home: const Scaffold(body: SizedBox.expand()),
      ),
    ),
  );
}

void main() {
  test('đăng nhập thì kết nối hub, đăng xuất thì ngắt kết nối', () async {
    final socket = FakeNotificationSocketClient();
    final container = _container(socket: socket);
    addTearDown(container.dispose);

    await container.read(authSessionProvider.future);
    container.read(notificationRealtimeViewModelProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(socket.connectCallCount, 1);
    expect(socket.lastHubUrl, endsWith('/hubs/notifications'));

    await container.read(authSessionProvider.notifier).signOut();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(socket.disconnectCallCount, greaterThanOrEqualTo(1));
  });

  test(
    'nhận notification realtime thì cập nhật feed và lastIncoming',
    () async {
      final socket = FakeNotificationSocketClient();
      final container = _container(socket: socket);
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);
      await container.read(notificationFeedViewModelProvider.future);
      container.read(notificationRealtimeViewModelProvider);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final notification = _notification();
      socket.emit(notification);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final feed = container.read(notificationFeedViewModelProvider).value!;
      expect(feed.items.map((item) => item.id), contains('realtime-1'));
      expect(
        container.read(notificationRealtimeViewModelProvider).lastIncoming?.id,
        'realtime-1',
      );

      socket.emit(notification);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final deduped = container.read(notificationFeedViewModelProvider).value!;
      expect(
        deduped.items.where((item) => item.id == 'realtime-1'),
        hasLength(1),
      );
    },
  );

  testWidgets('hiện SnackBar khi có thông báo realtime', (tester) async {
    final socket = FakeNotificationSocketClient();
    await tester.pumpWidget(_buildWidget(socket));
    await tester.pumpAndSettle();

    expect(socket.connectCallCount, 1);

    socket.emit(_notification());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Chương mới vừa ra mắt'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
  });
}
