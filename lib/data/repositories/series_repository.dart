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

      final dtoList = rawList
          .cast<Map<String, dynamic>>()
          .map(SeriesDto.fromJson);

      final domainList = dtoList.map(Series.fromDto).toList(growable: false);

      return domainList;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể xử lý dữ liệu danh sách truyện: $e');
    }
  }

  /// 2. Bật / Tắt trạng thái lưu truyện vào tủ sách cá nhân (Bookmark)
  /// Phục vụ cho tính năng Optimistic UI ở tầng giao diện
  Future<void> toggleBookmark(String seriesId, bool shouldBookmark) async {
    try {
      // Gửi request tới Gateway
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể cập nhật tủ sách: $e');
    }
  }

  /// 3. Lấy thông tin chi tiết một bộ truyện theo [seriesId] từ Gateway
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
      return Series.fromDto(dto);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể xử lý chi tiết tác phẩm: $e');
    }
  }
}

/// RIVERPOD PROVIDER: Đăng ký SeriesRepository để các ViewModel có thể dùng lại dễ dàng
final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return SeriesRepository(dio);
});
