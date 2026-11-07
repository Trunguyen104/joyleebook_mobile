import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/api_client.dart';
import '../../../data/services/api_exceptions.dart';
import '../../../routing/app_paths.dart';
import '../../auth/view_models/auth_session_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/notification_feed_view_model.dart';
import 'notification_item.dart';

/// Màn hình danh sách thông báo người dùng (Tab Thông báo trên NavigationBar).
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final session = ref.watch(authSessionProvider);
    final isSignedIn = session.value != null;

    final feedState = ref.watch(notificationFeedViewModelProvider);
    final viewModel = ref.read(notificationFeedViewModelProvider.notifier);
    final unreadCount = feedState.value?.unreadCount ?? 0;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông báo'),
            if (isSignedIn && unreadCount > 0)
              Text(
                '$unreadCount chưa đọc',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: colors.textMuted,
                ),
              ),
          ],
        ),
        centerTitle: false,
      ),
      body: !isSignedIn
          ? JoyleeEmptyState(
              iconData: Icons.notifications_none_rounded,
              title: 'Chưa đăng nhập',
              message: 'Vui lòng đăng nhập để xem các thông báo về truyện và tài khoản.',
              actionLabel: 'Đăng nhập',
              onAction: () => context.push(
                '${AppPaths.signIn}?from=${AppPaths.notifications}',
              ),
            )
          : feedState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => JoyleeErrorView(
                message: error is AppException
                    ? error.message
                    : 'Không thể tải thông báo. Vui lòng thử lại.',
                onRetry: viewModel.refresh,
              ),
              data: (feed) {
                if (feed.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: viewModel.refresh,
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: JoyleeEmptyState(
                              iconData: Icons.notifications_none_rounded,
                              title: 'Chưa có thông báo',
                              message: 'Các thông báo về truyện và tài khoản sẽ xuất hiện tại đây.',
                              actionLabel: 'Tải lại',
                              onAction: viewModel.refresh,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: viewModel.refresh,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 120) {
                        _loadMoreWithFeedback();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.space2,
                      ),
                      itemCount:
                          feed.items.length + (feed.isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.borderDefault,
                      ),
                      itemBuilder: (context, index) {
                        if (index == feed.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppDimensions.space4),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = feed.items[index];
                        return NotificationItem(
                          notification: item,
                          onTap: () => _markAsSeen(item.id),
                        );
                      },
                    ),
                  ),
                );
              },
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
