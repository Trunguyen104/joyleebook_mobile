import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/dtos/notification_dto.dart';
import 'package:joyleebook_mobile/domain/models/app_notification.dart';

void main() {
  test('parse đầy đủ NotificationDto và PagedNotificationsDto', () {
    final dto = NotificationDto.fromJson({
      'id': 'n1',
      'userId': 'u1',
      'type': 2,
      'title': 'Chương mới',
      'message': 'Truyện bạn theo dõi vừa có chương mới.',
      'readAt': null,
      'createdAt': '2026-11-01T10:00:00Z',
      'updatedAt': '2026-11-01T10:00:00Z',
    });

    expect(dto.id, 'n1');
    expect(dto.type, 2);
    expect(dto.readAtUtc, isNull);
    expect(dto.createdAtUtc, isNotNull);

    final page = PagedNotificationsDto.fromJson({
      'items': [
        {
          'id': 'n1',
          'userId': 'u1',
          'type': 2,
          'title': 'Chương mới',
          'createdAt': '2026-11-01T10:00:00Z',
          'updatedAt': '2026-11-01T10:00:00Z',
        },
      ],
      'page': 1,
      'pageSize': 20,
      'totalCount': 1,
    });

    expect(page.items, hasLength(1));
    expect(page.totalCount, 1);
  });

  test('items null và timestamp sai định dạng không làm sập app', () {
    final page = PagedNotificationsDto.fromJson({
      'items': null,
      'page': null,
      'pageSize': null,
      'totalCount': null,
    });

    expect(page.items, isEmpty);
    expect(page.page, 1);

    final notification = AppNotification.fromDto(
      NotificationDto.fromJson({
        'id': 'n2',
        'userId': 'u1',
        'type': 99,
        'createdAt': 'not-a-date',
        'updatedAt': null,
      }),
    );

    expect(notification.type, 99);
    expect(notification.title, 'Thông báo');
    expect(notification.message, isEmpty);
    expect(notification.createdAt, isNotNull);
  });
}
