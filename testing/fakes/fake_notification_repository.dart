import 'package:joyleebook_mobile/data/repositories/notification_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/app_notification.dart';

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({List<AppNotification>? items})
    : items = List.of(items ?? const []);

  List<AppNotification> items;
  AppException? error;
  AppException? markSeenError;

  int getCallCount = 0;
  int markSeenCallCount = 0;
  final List<String> markedSeenIds = [];

  @override
  Future<NotificationFeedPage> getNotifications({
    required String userId,
    int page = 1,
    int pageSize = 100,
  }) async {
    getCallCount++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (error != null) throw error!;

    final start = (page - 1) * pageSize;
    final pageItems = start >= items.length
        ? const <AppNotification>[]
        : items.skip(start).take(pageSize).toList(growable: false);

    return NotificationFeedPage(
      items: pageItems,
      page: page,
      pageSize: pageSize,
      totalCount: items.length,
    );
  }

  @override
  Future<AppNotification> markSeen(String notificationId) async {
    markSeenCallCount++;
    markedSeenIds.add(notificationId);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (markSeenError != null) throw markSeenError!;

    final index = items.indexWhere((item) => item.id == notificationId);
    if (index == -1) {
      throw const AppException(
        message: 'Không tìm thấy thông báo.',
        statusCode: 404,
      );
    }

    final updated = items[index].markReadAt(DateTime.now());
    items[index] = updated;
    return updated;
  }
}
