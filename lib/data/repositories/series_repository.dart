import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_endpoints.dart';
import '../../domain/models/series.dart';
import '../dtos/series_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';

/// REPOSITORY - Kho lưu trữ dữ liệu
/// Bước 3 trong kiến trúc Compass App:
/// Là lớp trung gian DUY NHẤT kết nối giữa Data Service (Dio/Mạng) và Giao diện (ViewModel).
class SeriesRepository {
  final Dio _dio;

  SeriesRepository(this._dio);

  /// 1. Lấy danh sách truyện từ Gateway
  /// Có hỗ trợ tham số tìm kiếm [searchQuery] nếu người dùng gõ từ khóa
  Future<List<Series>> getSeriesList({String? searchQuery}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.trim();
      }

      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.series,
        queryParameters: queryParams,
      );

      final rawList = response.data ?? [];

      final dtoList = rawList.cast<Map<String, dynamic>>().map(
        SeriesDto.fromJson,
      );

      final domainList = dtoList.map(Series.fromDto).toList(growable: false);

      return domainList;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Không thể xử lý dữ liệu danh sách truyện: $e',
      );
    }
  }

  /// 2. Bật / Tắt trạng thái lưu truyện vào tủ sách cá nhân (Bookmark)
  /// Kết nối tới JoyleeBook Library Microservice:
  /// - Thêm: POST /api/library/bookmarks {'seriesId': seriesId}
  /// - Xóa: DELETE /api/library/bookmarks/{seriesId}
  Future<void> toggleBookmark(String seriesId, bool shouldBookmark) async {
    try {
      if (shouldBookmark) {
        await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.libraryBookmarks,
          data: {'seriesId': seriesId},
        );
      } else {
        await _dio.delete<void>(
          ApiEndpoints.libraryBookmarkDelete(seriesId),
        );
      }
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể cập nhật tủ sách: $e');
    }
  }

  /// 3. Lấy thông tin chi tiết một bộ truyện theo [seriesId] từ Gateway
  /// Kết hợp dữ liệu từ:
  /// - Series Service: GET /api/series/{seriesId}
  /// - Community Service: GET /api/ratings/series/{seriesId} (thống kê rating)
  /// - Community Service: GET /api/ratings/series/{seriesId}/my-rating (đánh giá của bản thân nếu đã đăng nhập)
  Future<Series> getSeriesById(String seriesId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.series}/$seriesId',
      );

      final data = response.data;
      if (data == null) {
        throw AppException(message: 'Không tìm thấy thông tin tác phẩm.');
      }

      final dto = SeriesDto.fromJson(data);
      var averageRating = dto.averageRating;
      var totalRatings = dto.totalRatings;
      var userRating = dto.userRating;

      // 1. Đồng bộ điểm đánh giá từ Community Service nếu chưa có trong Series DTO
      try {
        final ratingRes = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.seriesRating(seriesId),
        );
        final ratingData = ratingRes.data;
        if (ratingData != null) {
          final avg = ratingData['averageRating'] as num?;
          final count = ratingData['totalRatings'] as int?;
          if (avg != null) averageRating = avg.toDouble();
          if (count != null) totalRatings = count;
        }
      } catch (_) {
        // Best-effort: Nếu Community Service chưa phản hồi, giữ nguyên giá trị từ Series DTO
      }

      // 2. Kiểm tra đánh giá của cá nhân người dùng hiện tại (nếu có đăng nhập)
      try {
        final myRatingRes = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.seriesMyRating(seriesId),
        );
        final myRatingData = myRatingRes.data;
        if (myRatingData != null && myRatingData['score'] != null) {
          userRating = (myRatingData['score'] as num?)?.toInt();
        }
      } catch (_) {
        // Chưa đăng nhập (401) hoặc chưa đánh giá (404) -> userRating giữ nguyên
      }

      return Series.fromDto(dto).copyWith(
        averageRating: averageRating,
        totalRatings: totalRatings,
        userRating: userRating,
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể xử lý chi tiết tác phẩm: $e');
    }
  }

  /// 4. Đánh giá hoặc cập nhật điểm đánh giá tác phẩm (Rate & Update Rating)
  /// Gửi request tới Community Microservice:
  /// - POST /api/ratings kèm body: {'seriesId': seriesId, 'score': score}
  /// Backend tự động tạo mới nếu chưa đánh giá, hoặc cập nhật điểm nếu đã đánh giá.
  Future<void> rateSeries(String seriesId, int score) async {
    if (score < 1 || score > 5) {
      throw AppException(
        message: 'Điểm đánh giá không hợp lệ. Vui lòng chọn từ 1 đến 5 sao.',
      );
    }

    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.ratings,
        data: {
          'seriesId': seriesId,
          'score': score,
        },
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể gửi đánh giá tác phẩm: $e');
    }
  }
}

/// RIVERPOD PROVIDER: Đăng ký SeriesRepository để các ViewModel có thể dùng lại dễ dàng
final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return SeriesRepository(dio);
});
