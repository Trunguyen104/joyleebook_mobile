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

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationFeedViewModelProvider);
    final viewModel = ref.read(notificationFeedViewModelProvider.notifier);
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            tooltip: 'Làm mới thông báo',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: viewModel.refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: state.when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.primaryBrand,
                  ),
                ),
                const SizedBox(height: AppDimensions.space3),
                Text(
                  'Đang tải thông báo...',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
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

            return RefreshIndicator(
              color: colors.primaryBrand,
              backgroundColor: colors.bgSurface,
              onRefresh: viewModel.refresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.extentAfter < 240) {
                    _loadMoreWithFeedback(context, ref);
                  }
                  return false;
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.space2,
                  ),
                  itemCount: feed.items.length + (feed.isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.borderDefault,
                  ),
                  itemBuilder: (context, index) {
                    if (index >= feed.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(AppDimensions.space4),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final item = feed.items[index];
                    return NotificationItem(
                      notification: item,
                      onTap: () => _markAsSeen(context, ref, item.id),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markAsSeen(
    BuildContext context,
    WidgetRef ref,
    String notificationId,
  ) async {
    final success = await ref
        .read(notificationFeedViewModelProvider.notifier)
        .markAsSeen(notificationId);

    if (!success && !ref.read(sessionExpiredProvider) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể đánh dấu đã đọc. Đã hoàn tác trạng thái.'),
        ),
      );
    }
  }

  Future<void> _loadMoreWithFeedback(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final error = await ref
        .read(notificationFeedViewModelProvider.notifier)
        .loadMore();

    if (error != null && !ref.read(sessionExpiredProvider) && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
