import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_endpoints.dart';
import '../../domain/models/app_notification.dart';
import '../dtos/notification_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<NotificationFeedPage> getNotifications({
    required String userId,
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsByUser(userId),
        queryParameters: {'Page': page, 'PageSize': pageSize},
      );

      final dto = PagedNotificationsDto.fromJson(response.data ?? const {});
      return NotificationFeedPage.fromDto(dto);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể xử lý danh sách thông báo: $e');
    }
  }

  Future<AppNotification> markSeen(String notificationId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.notificationSeen(notificationId),
      );

      final data = response.data;
      if (data == null) {
        throw const AppException(message: 'Không tìm thấy thông báo.');
      }

      return AppNotification.fromDto(NotificationDto.fromJson(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const AppException(
          message: 'Không tìm thấy thông báo.',
          statusCode: 404,
        );
      }
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể đánh dấu thông báo đã đọc: $e');
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});
