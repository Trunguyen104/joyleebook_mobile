import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_endpoints.dart';
import '../../domain/models/genre.dart';
import '../dtos/genre_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';

/// RIVERPOD PROVIDER: Đăng ký GenreRepository
final genreRepositoryProvider = Provider<GenreRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return GenreRepository(dio);
});

/// REPOSITORY - Kho lưu trữ dữ liệu Thể loại
/// Bước 3 trong kiến trúc Compass App:
/// Trung gian kết nối giữa Data Service (Dio) và UI (ViewModel).
class GenreRepository {
  final Dio _dio;

  GenreRepository(this._dio);

  /// Lấy danh sách thể loại từ JoyleeBook Gateway (GET /api/genres)
  Future<List<Genre>> getGenres() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.genres);
      final rawData = response.data;
      final List<dynamic> rawList;

      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map<String, dynamic>) {
        final nestedList = rawData['data'] ??
            rawData['items'] ??
            rawData['genres'] ??
            rawData['results'];
        if (nestedList is List) {
          rawList = nestedList;
        } else {
          rawList = const [];
        }
      } else {
        rawList = const [];
      }

      final dtoList = rawList
          .whereType<Map<String, dynamic>>()
          .map(GenreDto.fromJson)
          .toList();

      return dtoList.map(Genre.fromDto).toList(growable: false);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Không thể xử lý dữ liệu danh mục thể loại: $e',
      );
    }
  }
}
