import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/series.dart';
import '../dtos/series_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';

/// REPOSITORY - Kho lưu trữ dữ liệu
/// Bước 3 trong kiến trúc Compass App:
/// Là lớp trung gian DUY NHẤT kết nối giữa Data Service (Dio/Mạng) và Giao diện (ViewModel).
/// 
/// VAI TRÒ CHÍNH:
/// 1. Gửi request mạng qua Dio tới Gateway.
/// 2. Bắt các ngoại lệ mạng (DioException) và chuyển hóa thành AppException thân thiện.
/// 3. Chuyển đổi toàn bộ DTO thành Domain Model sạch trước khi trả về.
class SeriesRepository {
  final Dio _dio;

  SeriesRepository(this._dio);

  /// 1. Lấy danh sách truyện từ Gateway
  /// Có hỗ trợ tham số tìm kiếm [searchQuery] nếu người dùng gõ từ khóa
  Future<List<Series>> getSeriesList({String? searchQuery}) async {
    try {
      // Chuẩn bị tham số truy vấn (Query Parameters)
      final queryParams = <String, dynamic>{};
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.trim();
      }

      // Gửi HTTP GET tới API Gateway: <API_BASE_URL>/api/series
      final response = await _dio.get<List<dynamic>>(
        '/api/series',
        queryParameters: queryParams,
      );

      // Nếu dữ liệu rỗng thì trả về danh sách rỗng
      final rawList = response.data ?? [];

      // Bước chuyển đổi 2 chặng:
      // Chặng A: JSON Map -> SeriesDto (Data)
      // Chặng B: SeriesDto -> Series (Domain Model)
      final dtoList = rawList
          .cast<Map<String, dynamic>>()
          .map(SeriesDto.fromJson);

      final domainList = dtoList.map(Series.fromDto).toList(growable: false);

      return domainList;
    } on DioException catch (e) {
      // Bắt lỗi Dio (mất mạng, timeout, 502) và bọc thành AppException
      throw AppException.fromDio(e);
    } catch (e) {
      // Bắt các lỗi phân tích JSON hoặc lỗi logic khác
      throw AppException(message: 'Không thể xử lý dữ liệu danh sách truyện: $e');
    }
  }

  /// 2. Bật / Tắt trạng thái lưu truyện vào tủ sách cá nhân (Bookmark)
  /// Phục vụ cho tính năng Optimistic UI ở tầng giao diện
  Future<void> toggleBookmark(String seriesId, bool shouldBookmark) async {
    try {
      // Gửi request tới Gateway
      // Ghi chú: Nếu backend chưa hỗ trợ đầy đủ API bookmarks, ta delay nhẹ giả lập
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// 3. Lấy thông tin chi tiết một bộ truyện theo [seriesId] từ Gateway
  Future<Series> getSeriesById(String seriesId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/series/',
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
      throw AppException(message: 'Không thể xử lý chi tiết tác phẩm: ');
    }
  }
}

/// RIVERPOD PROVIDER: Đăng ký SeriesRepository để các ViewModel có thể dùng lại dễ dàng
final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  // Lấy Dio client đã cấu hình sẵn base URL của Gateway
  final dio = ref.watch(apiClientProvider);
  return SeriesRepository(dio);
});
