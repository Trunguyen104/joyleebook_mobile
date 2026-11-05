import 'package:joyleebook_mobile/data/services/notification_socket_client.dart';
import 'package:joyleebook_mobile/domain/models/app_notification.dart';

/// Socket giả cho test: không mở kết nối mạng, cho phép phát sự kiện thủ công.
class FakeNotificationSocketClient implements NotificationSocketClient {
  int connectCallCount = 0;
  int disconnectCallCount = 0;
  String? lastHubUrl;
  Object? connectError;

  void Function(AppNotification notification)? _onNotification;
  void Function()? _onClosed;

  @override
  Future<void> connect({
    required String hubUrl,
    required Future<String?> Function() accessTokenFactory,
    required void Function(AppNotification notification) onNotification,
    void Function()? onClosed,
  }) async {
    connectCallCount++;
    lastHubUrl = hubUrl;
    _onNotification = onNotification;
    _onClosed = onClosed;
    if (connectError != null) throw connectError!;
  }

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
    _onNotification = null;
    _onClosed = null;
  }

  void emit(AppNotification notification) {
    _onNotification?.call(notification);
  }

  void emitClosed() {
    _onClosed?.call();
  }
}
