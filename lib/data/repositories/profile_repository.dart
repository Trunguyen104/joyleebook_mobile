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
            'utcOffSetMinutes': DateTime.now().timeZoneOffset.inMinutes,
          },
        ),
      ]);

      final profileDto = ProfileDto.fromJson(response[0].data ?? const {});

      final statsDto = ReadingStatsDto.fromJson(response[1].data ?? const {});

      return _toDomain(profileDto, statsDto);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  UserProfile _toDomain(ProfileDto profile, ReadingStatsDto stats) =>
      UserProfile(
        id: profile.id,
        username: profile.username,
        displayName: profile.displayName,
        bio: profile.bio,
        avatarUrl: profile.avatarUrl,
        email: profile.email,
        role: UserRole.fromString(profile.role),
        stats: ReadingStats(
          seriesStarted: stats.seriesStarted,
          chaptersCompleted: stats.chaptersCompleted,
          currentStreakDays: stats.currentStreakDays,
          longestStreakDays: stats.longestStreakDays,
          lastReadAt: stats.lastReadAtUtc?.toLocal(),
        ),
      );
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);
