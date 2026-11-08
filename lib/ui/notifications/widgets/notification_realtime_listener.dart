import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/app_notification.dart';
import '../../core/services/app_messenger.dart';
import '../view_models/notification_realtime_view_model.dart';

/// Giữ kết nối realtime sống ở gốc app và hiện SnackBar khi có thông báo mới.
class NotificationRealtimeListener extends ConsumerWidget {
  const NotificationRealtimeListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<NotificationRealtimeState>(
      notificationRealtimeViewModelProvider,
      (previous, next) {
        final incoming = next.lastIncoming;
        if (incoming == null || incoming.id == previous?.lastIncoming?.id) {
          return;
        }
        _showNotification(incoming);
      },
    );

    return child;
  }

  void _showNotification(AppNotification notification) {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${notification.title}\n${notification.message}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
  }
}
