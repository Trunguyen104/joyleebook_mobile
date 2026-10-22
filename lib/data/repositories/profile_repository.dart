import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joyleebook_mobile/config/api_endpoints.dart';
import 'package:joyleebook_mobile/data/dtos/profile_dto.dart';
import 'package:joyleebook_mobile/data/dtos/reading_stats_dto.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<UserProfile> getMyProfile() async {
    try {
      final response = await Future.wait([
        _dio.get<Map<String, dynamic>>(ApiEndpoints.profiles),
        _dio.get<Map<String, dynamic>>(
          ApiEndpoints.libraryStats,
          queryParameters: {
            'days': 30,
            'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
          },
        ),
      ]);

      final profileDto = ProfileDto.fromJson(response[0].data ?? const {});
      final statsDto = ReadingStatsDto.fromJson(response[1].data ?? const {});

      return UserProfile.fromDto(profileDto, statsDto);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể xử lý dữ liệu hồ sơ cá nhân: $e');
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);
