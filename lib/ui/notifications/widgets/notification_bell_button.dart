import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_paths.dart';
import '../../auth/view_models/auth_session_view_model.dart';
import '../../core/widgets/joylee_notification_bell.dart';
import '../view_models/notification_feed_view_model.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (session.value == null) return const SizedBox.shrink();

    final unreadCount =
        ref.watch(notificationFeedViewModelProvider).value?.unreadCount ?? 0;

    return JoyleeNotificationBell(
      unreadCount: unreadCount,
      onPressed: () => context.push(AppPaths.notifications),
    );
  }
}
