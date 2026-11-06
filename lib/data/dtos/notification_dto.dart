import 'package:flutter/foundation.dart';

@immutable
class NotificationDto {
  final String id;
  final String userId;
  final int type;
  final String? title;
  final String? message;
  final DateTime? readAtUtc;
  final DateTime? createdAtUtc;
  final DateTime? updatedAtUtc;

  const NotificationDto({
    required this.id,
    required this.userId,
    required this.type,
    this.title,
    this.message,
    this.readAtUtc,
    this.createdAtUtc,
    this.updatedAtUtc,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      type: (json['type'] as num?)?.toInt() ?? 0,
      title: json['title'] as String?,
      message: json['message'] as String?,
      readAtUtc: _parseDate(json['readAt'] ?? json['readAtUtc']),
      createdAtUtc: _parseDate(json['createdAt'] ?? json['createdAtUtc']),
      updatedAtUtc: _parseDate(json['updatedAt'] ?? json['updatedAtUtc']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

@immutable
class PagedNotificationsDto {
  final List<NotificationDto> items;
  final int page;
  final int pageSize;
  final int totalCount;

  const PagedNotificationsDto({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  factory PagedNotificationsDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(NotificationDto.fromJson)
        .toList(growable: false);

    return PagedNotificationsDto(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? items.length,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? items.length,
    );
  }
}
