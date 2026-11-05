import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/api_client.dart';
import '../../../data/services/api_exceptions.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/notification_feed_view_model.dart';
import 'notification_item.dart';

class NotificationPopup extends ConsumerStatefulWidget {
  const NotificationPopup({
    super.key,
    required this.maxHeight,
    required this.onClose,
  });

  final double maxHeight;
  final VoidCallback onClose;

  @override
  ConsumerState<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends ConsumerState<NotificationPopup> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final feedState = ref.watch(notificationFeedViewModelProvider);
    final viewModel = ref.read(notificationFeedViewModelProvider.notifier);
    final unreadCount = feedState.value?.unreadCount ?? 0;

    return Material(
      color: colors.bgSurface,
      elevation: 12,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppDimensions.space4,
                right: AppDimensions.space1,
                top: AppDimensions.space3,
                bottom: AppDimensions.space3,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_rounded,
                    color: colors.primaryBrand,
                    size: 22,
                  ),
                  const SizedBox(width: AppDimensions.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông báo',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (unreadCount > 0)
                          Text(
                            '$unreadCount chưa đọc',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng thông báo',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: colors.borderDefault),
            Flexible(
              child: feedState.when(
                loading: () => const SizedBox.shrink(),
                error: (error, _) => JoyleeErrorView(
                  message: error is AppException
                      ? error.message
                      : 'Không thể tải thông báo. Vui lòng thử lại.',
                  onRetry: viewModel.refresh,
                ),
                data: (feed) {
                  if (feed.items.isEmpty) {
                    return JoyleeEmptyState(
                      iconData: Icons.notifications_none_rounded,
                      title: 'Chưa có thông báo',
                      message: 'Các thông báo về truyện và tài khoản sẽ xuất hiện tại đây.',
                      actionLabel: 'Tải lại',
                      onAction: viewModel.refresh,
                    );
                  }

                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 120) {
                        _loadMoreWithFeedback();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.space1,
                      ),
                      itemCount: feed.items.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.borderDefault,
                      ),
                      itemBuilder: (context, index) {
                        final item = feed.items[index];
                        return NotificationItem(
                          notification: item,
                          onTap: () => _markAsSeen(item.id),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsSeen(String notificationId) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(notificationFeedViewModelProvider.notifier)
        .markAsSeen(notificationId);

    if (!success && !ref.read(sessionExpiredProvider) && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không thể đánh dấu đã đọc. Đã hoàn tác trạng thái.'),
        ),
      );
    }
  }

  Future<void> _loadMoreWithFeedback() async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref
        .read(notificationFeedViewModelProvider.notifier)
        .loadMore();

    if (error != null && !ref.read(sessionExpiredProvider) && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
