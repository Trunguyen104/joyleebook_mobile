import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joyleebook_mobile/config/api_endpoints.dart';
import 'package:joyleebook_mobile/data/dtos/profile_dto.dart';
import 'package:joyleebook_mobile/data/dtos/reading_stats_dto.dart';
import 'package:joyleebook_mobile/data/dtos/update_profile_request_dto.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserProfile> getMyProfile() async {
    try {
      final profileResponse = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.profiles,
      );

      final rawProfile = profileResponse.data ?? const {};
      final profileData = rawProfile['data'] is Map<String, dynamic>
          ? rawProfile['data'] as Map<String, dynamic>
          : rawProfile;

      final profileDto = ProfileDto.fromJson(profileData);

      // Thống kê đọc: gọi bất đồng bộ riêng biệt, nếu thư viện lỗi thì KHÔNG làm hỏng hồ sơ
      ReadingStatsDto statsDto = const ReadingStatsDto();
      try {
        final statsResponse = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.libraryStats,
          queryParameters: {
            'days': 30,
            'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
          },
        );
        final rawStats = statsResponse.data ?? const {};
        final statsData = rawStats['data'] is Map<String, dynamic>
            ? rawStats['data'] as Map<String, dynamic>
            : rawStats;
        statsDto = ReadingStatsDto.fromJson(statsData);
      } catch (_) {
        // Nếu API thống kê đọc không khả dụng hoặc chưa có dữ liệu, dùng stats mặc định
      }

      return UserProfile.fromDto(profileDto, statsDto);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể xử lý dữ liệu hồ sơ cá nhân: $e');
    }
  }

  Future<UserProfile> updateMyProfile({
    required String? displayName,
    required String? bio,
    required String? avatarUrl,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.profiles,
        data: UpdateProfileRequestDto(
          displayName: displayName,
          bio: bio,
          avatarUrl: avatarUrl,
        ).toJson(),
      );

      final raw = response.data ?? const {};
      final profileData = raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : raw;
      final profileDto = ProfileDto.fromJson(profileData);
      return UserProfile.fromDto(profileDto);
    } on DioException catch (e) {
      throw _mapUpdateError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể xử lý dữ liệu hồ sơ cá nhân: $e');
    }
  }

  /// Backend trả ValidationProblemDetails khi dữ liệu sai; đổi sang lỗi
  /// tiếng Việt gắn với từng ô nhập của form.
  AppException _mapUpdateError(DioException error) {
    final data = error.response?.data;
    if (error.response?.statusCode == 400 && data is Map) {
      final rawErrors = data['errors'];
      final fieldErrors = <String, String>{};
      if (rawErrors is Map) {
        for (final key in rawErrors.keys) {
          final field = key.toString().toLowerCase();
          final message = switch (field) {
            'displayname' => 'Tên hiển thị tối đa 64 ký tự.',
            'bio' => 'Giới thiệu tối đa 500 ký tự.',
            'avatarurl' => 'Ảnh đại diện không hợp lệ. Vui lòng chọn ảnh khác.',
            _ => null,
          };
          if (message != null) fieldErrors[field] = message;
        }
      }
      return AppException(
        message: 'Dữ liệu hồ sơ không hợp lệ.',
        statusCode: 400,
        fieldErrors: fieldErrors.isEmpty ? null : fieldErrors,
      );
    }
    return AppException.fromDio(error);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);
