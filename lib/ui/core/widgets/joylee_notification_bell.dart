import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

class JoyleeNotificationBell extends StatelessWidget {
  const JoyleeNotificationBell({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = unreadCount < 0 ? 0 : unreadCount;
    final badgeLabel = count > 99 ? '99+' : '$count';

    return IconButton(
      tooltip: count > 0 ? 'Thông báo, $count chưa đọc' : 'Thông báo',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(badgeLabel),
        backgroundColor: colors.danger,
        textColor: colors.textOnBrand,
        child: Icon(
          count > 0
              ? Icons.notifications_rounded
              : Icons.notifications_outlined,
        ),
      ),
    );
  }
}
