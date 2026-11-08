import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joyleebook_mobile/config/api_endpoints.dart';
import 'package:joyleebook_mobile/data/dtos/upload_media_response_dto.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';

class MediaRepository {
  MediaRepository(this._dio);

  final Dio _dio;

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.mediaUploadAvatar,
        data: FormData.fromMap({
          'File': MultipartFile.fromBytes(bytes, filename: fileName),
        }),
      );

      final dto = UploadMediaResponseDto.fromJson(response.data ?? const {});
      final url = dto.url?.trim();
      if (url == null || url.isEmpty) {
        throw const AppException(
          message: 'Máy chủ không trả về đường dẫn ảnh đại diện.',
        );
      }
      return url;
    } on DioException catch (e) {
      throw _mapUploadError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException(
        message: 'Không thể tải ảnh lên. Vui lòng thử lại.',
      );
    }
  }

  AppException _mapUploadError(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map) {
      final code = data['errorCode']?.toString();
      final message = switch (code) {
        'Media.FileEmpty' => 'Vui lòng chọn một ảnh đại diện.',
        'Media.FileTooLarge' =>
          'Ảnh đại diện vượt quá dung lượng 2MB. Vui lòng chọn ảnh nhỏ hơn.',
        'Media.InvalidFormat' => 'Chỉ hỗ trợ ảnh JPG, JPEG, PNG hoặc WEBP.',
        'Media.InvalidId' || 'Media.MissingUserId' =>
          'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
        'Media.NotConfigured' => 'Dịch vụ lưu trữ ảnh chưa được cấu hình. Vui lòng liên hệ quản trị viên.',
        'Media.CloudinaryError' ||
        'Media.UploadException' => 'Không thể tải ảnh lên. Vui lòng thử lại.',
        _ => null,
      };
      if (message != null) {
        return AppException(message: message, statusCode: status);
      }

      final detail = data['detail']?.toString().trim();
      if (detail != null && detail.isNotEmpty) {
        return AppException(message: detail, statusCode: status);
      }
    }

    if (status == 502) {
      return const AppException(
        message:
            'Gateway đang chạy nhưng dịch vụ ảnh chưa được bật (HTTP 502).',
        statusCode: 502,
      );
    }
    if (status == 413) {
      return const AppException(
        message:
            'Ảnh đại diện vượt quá dung lượng 2MB. Vui lòng chọn ảnh nhỏ hơn.',
        statusCode: 413,
      );
    }
    if (status == 415) {
      return const AppException(
        message: 'Chỉ hỗ trợ ảnh JPG, JPEG, PNG hoặc WEBP.',
        statusCode: 415,
      );
    }

    return AppException.fromDio(error);
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepository(ref.watch(apiClientProvider)),
);
