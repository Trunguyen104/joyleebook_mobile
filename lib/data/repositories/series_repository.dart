import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_endpoints.dart';
import '../../domain/models/series.dart';
import '../dtos/bookmark_dto.dart';
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
  Future<List<Series>> getSeriesList({
    String? searchQuery,
    String? genre,
    SeriesStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.trim();
      }
      if (genre != null && genre.trim().isNotEmpty) {
        queryParams['genre'] = genre.trim();
      }
      if (status != null) {
        queryParams['status'] = status == SeriesStatus.completed ? 0 : 1;
      }

      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.series,
        queryParameters: queryParams,
      );

      final rawList = response.data ?? [];

      final dtoList = rawList.cast<Map<String, dynamic>>().map(
        SeriesDto.fromJson,
      );

      var domainList = dtoList.map(Series.fromDto).toList(growable: false);

      if (genre != null && genre.trim().isNotEmpty) {
        final targetGenre = genre.trim().toLowerCase();
        domainList = domainList
            .where(
              (s) => s.genres.any(
                (item) =>
                    item.toLowerCase() == targetGenre ||
                    item.toLowerCase().contains(targetGenre),
              ),
            )
            .toList(growable: false);
      }
      if (status != null) {
        domainList =
            domainList.where((s) => s.status == status).toList(growable: false);
      }

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
        await _dio.post<void>(
          ApiEndpoints.libraryBookmarks,
          data: BookmarkSeriesDto(seriesId: seriesId).toJson(),
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

  /// Lấy các tác phẩm đã lưu trong tủ sách.
  Future<List<Series>> getBookmarkedSeries() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.libraryBookmarks);
      final rows = _bookmarkRows(response.data);
      final series = <Series>[];

      for (final row in rows) {
        if (row is! Map<String, dynamic>) {
          throw const AppException(
            message: 'Dữ liệu tủ sách không đúng định dạng.',
          );
        }

        final bookmark = BookmarkSeriesDto.fromJson(row);
        if (bookmark.seriesId.isEmpty) {
          throw const AppException(
            message: 'Thiếu mã tác phẩm trong dữ liệu tủ sách.',
          );
        }

        final rawSeries = bookmark.series ?? row;
        if (_hasSeriesDetails(rawSeries)) {
          final json = Map<String, dynamic>.from(rawSeries)
            // Bản ghi bookmark có thể có id riêng; thao tác API cần seriesId.
            ..['id'] = bookmark.seriesId;
          series.add(
            Series.fromDto(SeriesDto.fromJson(json), isBookmarked: true),
          );
        } else {
          final details = await getSeriesById(bookmark.seriesId);
          series.add(details.copyWith(isBookmarked: true));
        }
      }

      return series;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải tủ sách cá nhân: $e');
    }
  }

  /// Kiểm tra tác phẩm đã được lưu vào tủ sách hay chưa.
  Future<bool> getBookmarkStatus(String seriesId) async {
    try {
      final response = await _dio.get<dynamic>(
        '${ApiEndpoints.libraryBookmarks}/$seriesId/status',
      );
      return _parseBookmarkStatus(response.data);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể kiểm tra trạng thái tủ sách: $e');
    }
  }

  bool _parseBookmarkStatus(dynamic data) {
    if (data is bool) return data;
    if (data is Map<String, dynamic>) {
      for (final key in const [
        'isBookmarked',
        'bookmarked',
        'isSaved',
        'exists',
      ]) {
        if (data[key] is bool) return data[key] as bool;
      }
      for (final key in const ['data', 'status']) {
        if (data.containsKey(key)) return _parseBookmarkStatus(data[key]);
      }
    }
    throw const AppException(
      message: 'Phản hồi trạng thái tủ sách không đúng định dạng.',
    );
  }

  List<dynamic> _bookmarkRows(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      for (final key in const ['items', 'bookmarks', 'results', 'data']) {
        final value = data[key];
        if (value is List<dynamic>) return value;
        if (value is Map<String, dynamic>) {
          return _bookmarkRows(value);
        }
      }
      if (data.containsKey('seriesId') || data.containsKey('id')) {
        return [data];
      }
    }
    throw const AppException(message: 'Dữ liệu tủ sách không đúng định dạng.');
  }

  bool _hasSeriesDetails(Map<String, dynamic> json) =>
      json['title'] is String && json['title'].toString().isNotEmpty;

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
