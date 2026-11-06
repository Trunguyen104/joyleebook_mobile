import 'package:flutter/material.dart';

import '../../../domain/models/app_notification.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final isUnread = !notification.isRead;

    return Semantics(
      label: isUnread ? 'Chưa đọc' : 'Đã đọc',
      button: true,
      child: Material(
        color: isUnread ? colors.bgBrandSubtle : colors.bgSurface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space4,
              vertical: AppDimensions.space4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isUnread ? colors.bgSurface : colors.bgSurfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 20,
                    color: isUnread ? colors.primaryBrand : colors.textMuted,
                  ),
                ),
                const SizedBox(width: AppDimensions.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isUnread) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space2),
                          ],
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (notification.message.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.space1),
                        Text(
                          notification.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.space2),
                      Text(
                        formatNotificationTime(notification.createdAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String formatNotificationTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.isNegative || diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';

  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(time.day)}/${twoDigits(time.month)}/${time.year}';
}
