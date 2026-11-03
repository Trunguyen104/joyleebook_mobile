import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/notification_repository.dart';
import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/app_notification.dart';
import '../../../domain/models/auth_session.dart';
import '../../auth/view_models/auth_session_view_model.dart';

@immutable
class NotificationFeedState {
  final List<AppNotification> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool isLoadingMore;

  const NotificationFeedState({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    this.isLoadingMore = false,
  });

  const NotificationFeedState.empty()
    : items = const [],
      page = 0,
      pageSize = 100,
      totalCount = 0,
      isLoadingMore = false;

  int get unreadCount => items.where((item) => !item.isRead).length;

  bool get hasMore => totalCount > items.length;

  NotificationFeedState copyWith({
    List<AppNotification>? items,
    int? page,
    int? pageSize,
    int? totalCount,
    bool? isLoadingMore,
  }) {
    return NotificationFeedState(
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final notificationFeedViewModelProvider =
    AsyncNotifierProvider<NotificationFeedViewModel, NotificationFeedState>(
      NotificationFeedViewModel.new,
      retry: (retryCount, error) => null,
    );

class NotificationFeedViewModel extends AsyncNotifier<NotificationFeedState> {
  static const int _pageSize = 100;

  @override
  Future<NotificationFeedState> build() async {
    final session = await ref.watch(authSessionProvider.future);
    return _fetchFirstPage(session);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(authSessionProvider.future);
      return _fetchFirstPage(session);
    });
  }

  Future<String?> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return null;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final userId = await _requireUserId();
      final nextPage = await ref
          .read(notificationRepositoryProvider)
          .getNotifications(
            userId: userId,
            page: current.page + 1,
            pageSize: current.pageSize > 0 ? current.pageSize : _pageSize,
          );

      final latest = state.value ?? current;
      final existingIds = latest.items.map((item) => item.id).toSet();
      final merged = [
        ...latest.items,
        ...nextPage.items.where((item) => existingIds.add(item.id)),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      state = AsyncData(
        latest.copyWith(
          items: merged,
          page: nextPage.page,
          pageSize: nextPage.pageSize,
          totalCount: nextPage.totalCount,
          isLoadingMore: false,
        ),
      );
      return null;
    } catch (e) {
      final latest = state.value ?? current;
      state = AsyncData(latest.copyWith(isLoadingMore: false));
      return e is AppException
          ? e.message
          : 'Không thể tải thêm thông báo. Vui lòng thử lại.';
    }
  }

  Future<bool> markAsSeen(String notificationId) async {
    final current = state.value;
    if (current == null) return false;

    final targetIndex = current.items.indexWhere(
      (item) => item.id == notificationId,
    );
    if (targetIndex == -1) return false;

    final originalItem = current.items[targetIndex];
    if (originalItem.isRead) return true;

    final updatedItems = List<AppNotification>.from(current.items);
    updatedItems[targetIndex] = originalItem.markReadAt(DateTime.now());
    state = AsyncData(current.copyWith(items: updatedItems));

    try {
      final serverItem = await ref
          .read(notificationRepositoryProvider)
          .markSeen(notificationId);

      final latest = state.value ?? current;
      final latestIndex = latest.items.indexWhere(
        (item) => item.id == notificationId,
      );
      if (latestIndex != -1) {
        final items = List<AppNotification>.from(latest.items);
        items[latestIndex] = serverItem;
        state = AsyncData(latest.copyWith(items: items));
      }
      return true;
    } catch (_) {
      final latest = state.value ?? current;
      final rollbackIndex = latest.items.indexWhere(
        (item) => item.id == notificationId,
      );
      if (rollbackIndex != -1) {
        final items = List<AppNotification>.from(latest.items);
        items[rollbackIndex] = originalItem;
        state = AsyncData(latest.copyWith(items: items));
      }
      return false;
    }
  }

  Future<NotificationFeedState> _fetchFirstPage(AuthSession? session) async {
    if (session == null) {
      return const NotificationFeedState.empty();
    }

    final userId = session.userId.trim();
    if (userId.isEmpty) {
      throw const AppException(
        message: 'Không xác định được người dùng. Vui lòng đăng nhập lại.',
        statusCode: 401,
      );
    }

    final page = await ref
        .read(notificationRepositoryProvider)
        .getNotifications(userId: userId, page: 1, pageSize: _pageSize);

    final items = List<AppNotification>.from(page.items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return NotificationFeedState(
      items: items,
      page: page.page,
      pageSize: page.pageSize > 0 ? page.pageSize : _pageSize,
      totalCount: page.totalCount,
    );
  }

  Future<String> _requireUserId() async {
    final session = await ref.read(authSessionProvider.future);
    final userId = session?.userId.trim() ?? '';
    if (userId.isEmpty) {
      throw const AppException(
        message: 'Không xác định được người dùng. Vui lòng đăng nhập lại.',
        statusCode: 401,
      );
    }
    return userId;
  }
}
