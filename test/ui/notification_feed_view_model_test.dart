import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/notification_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/app_notification.dart';
import 'package:joyleebook_mobile/ui/notifications/view_models/notification_feed_view_model.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_notification_repository.dart';

List<AppNotification> _items(int count) {
  final now = DateTime.now();
  return List.generate(count, (index) {
    return AppNotification(
      id: 'n$index',
      userId: fakeSession.userId,
      type: 0,
      title: 'Thông báo $index',
      message: 'Nội dung $index',
      createdAt: now.subtract(Duration(minutes: index)),
      updatedAt: now.subtract(Duration(minutes: index)),
    );
  });
}

ProviderContainer _container(FakeNotificationRepository repo) {
  return ProviderContainer(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(savedSession: fakeSession),
      ),
    ],
  );
}

void main() {
  test('tải trang đầu và tải thêm trang kế tiếp', () async {
    final repo = FakeNotificationRepository(items: _items(150));
    final container = _container(repo);
    addTearDown(container.dispose);

    final first = await container.read(
      notificationFeedViewModelProvider.future,
    );

    expect(first.items, hasLength(100));
    expect(first.totalCount, 150);
    expect(first.hasMore, isTrue);
    expect(first.unreadCount, 100);
    expect(repo.getCallCount, 1);

    final error = await container
        .read(notificationFeedViewModelProvider.notifier)
        .loadMore();

    final loaded = container.read(notificationFeedViewModelProvider).value!;
    expect(error, isNull);
    expect(loaded.items, hasLength(150));
    expect(loaded.hasMore, isFalse);
    expect(loaded.unreadCount, 150);
    expect(repo.getCallCount, 2);
  });

  test('markAsSeen cập nhật lạc quan và rollback khi lỗi', () async {
    final repo = FakeNotificationRepository(items: _items(2));
    final container = _container(repo);
    addTearDown(container.dispose);

    await container.read(notificationFeedViewModelProvider.future);
    final viewModel = container.read(
      notificationFeedViewModelProvider.notifier,
    );

    final success = await viewModel.markAsSeen('n0');
    var feed = container.read(notificationFeedViewModelProvider).value!;
    expect(success, isTrue);
    expect(feed.unreadCount, 1);
    expect(repo.markSeenCallCount, 1);

    repo.markSeenError = const AppException(message: 'Lỗi máy chủ.');
    final failed = await viewModel.markAsSeen('n1');
    feed = container.read(notificationFeedViewModelProvider).value!;
    expect(failed, isFalse);
    expect(feed.unreadCount, 1);
  });
}
