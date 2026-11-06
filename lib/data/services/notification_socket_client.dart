import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../domain/models/app_notification.dart';
import '../dtos/notification_dto.dart';

/// Kết nối SignalR tới Notification Hub. Chỉ lắng nghe,
/// không gọi hàm nghiệp vụ nào trên server.
abstract interface class NotificationSocketClient {
  Future<void> connect({
    required String hubUrl,
    required Future<String?> Function() accessTokenFactory,
    required void Function(AppNotification notification) onNotification,
    void Function()? onClosed,
  });

  Future<void> disconnect();
}

class SignalRNotificationSocketClient implements NotificationSocketClient {
  static const _receiveNotificationMethod = 'ReceiveNotification';

  HubConnection? _connection;
  int _generation = 0;

  @override
  Future<void> connect({
    required String hubUrl,
    required Future<String?> Function() accessTokenFactory,
    required void Function(AppNotification notification) onNotification,
    void Function()? onClosed,
  }) async {
    final generation = ++_generation;
    await _stopConnection();
    if (generation != _generation) return;

    final connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async =>
                await accessTokenFactory() ?? '',
            transport: HttpTransportType.WebSockets,
            requestTimeout: 15000,
          ),
        )
        .withAutomaticReconnect(
          retryDelays: const [0, 2000, 5000, 10000, 30000],
        )
        .build();

    _connection = connection;

    connection.on(_receiveNotificationMethod, (arguments) {
      final payload = (arguments == null || arguments.isEmpty)
          ? null
          : arguments.first;
      if (payload is! Map) return;

      try {
        final json = Map<String, dynamic>.from(payload);
        onNotification(
          AppNotification.fromDto(NotificationDto.fromJson(json)),
        );
      } catch (_) {
        // Payload lạ không được làm sập kết nối realtime.
      }
    });

    connection.onclose(({error}) {
      if (generation == _generation) onClosed?.call();
    });

    try {
      await connection.start();
    } catch (_) {
      if (identical(_connection, connection)) _connection = null;
      try {
        await connection.stop();
      } catch (_) {
        // Bỏ qua lỗi đóng kết nối đã hỏng.
      }
      rethrow;
    }

    if (generation != _generation) {
      await connection.stop();
    }
  }

  @override
  Future<void> disconnect() async {
    _generation++;
    await _stopConnection();
  }

  Future<void> _stopConnection() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) return;

    try {
      await connection.stop();
    } catch (_) {
      // Kết nối đã đóng hoặc chưa mở xong.
    }
  }
}

final notificationSocketClientProvider = Provider<NotificationSocketClient>(
  (ref) => SignalRNotificationSocketClient(),
);
