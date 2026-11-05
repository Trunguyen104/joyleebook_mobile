import 'package:flutter/foundation.dart';

import '../../data/dtos/notification_dto.dart';

@immutable
class AppNotification {
  final String id;
  final String userId;
  final int type;
  final String title;
  final String message;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromDto(NotificationDto dto) {
    final now = DateTime.now();
    return AppNotification(
      id: dto.id,
      userId: dto.userId,
      type: dto.type,
      title: _fallbackText(dto.title, 'Thông báo'),
      message: _fallbackText(dto.message, ''),
      readAt: dto.readAtUtc?.toLocal(),
      createdAt: dto.createdAtUtc?.toLocal() ?? now,
      updatedAt: dto.updatedAtUtc?.toLocal() ?? now,
    );
  }

  bool get isRead => readAt != null;

  AppNotification markReadAt(DateTime time) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      message: message,
      readAt: time,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static String _fallbackText(String? value, String fallback) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? fallback : trimmed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          id == other.id &&
          userId == other.userId &&
          type == other.type &&
          title == other.title &&
          message == other.message &&
          readAt == other.readAt &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    type,
    title,
    message,
    readAt,
    createdAt,
    updatedAt,
  );
}

@immutable
class NotificationFeedPage {
  final List<AppNotification> items;
  final int page;
  final int pageSize;
  final int totalCount;

  const NotificationFeedPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  factory NotificationFeedPage.fromDto(PagedNotificationsDto dto) {
    return NotificationFeedPage(
      items: dto.items.map(AppNotification.fromDto).toList(growable: false),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }
}
