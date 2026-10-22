import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_endpoints.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/chapter_detail.dart';
import '../dtos/chapter_detail_dto.dart';
import '../dtos/chapter_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';

/// RIVERPOD PROVIDER: Đăng ký ChapterRepository
final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return ChapterRepository(dio);
});

/// REPOSITORY - Kho lưu trữ dữ liệu chương truyện
class ChapterRepository {
  final Dio _dio;

  ChapterRepository(this._dio);

  /// 1. Lấy danh sách chương của một bộ truyện theo [seriesId]
  Future<List<Chapter>> getChaptersBySeries(String seriesId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.chapters,
        queryParameters: {
          'seriesId': seriesId,
          'page': 1,
          'pageSize': 100,
          'sortDescending': false,
        },
      );

      final data = response.data;
      List<dynamic> rawList = [];

      if (data is Map<String, dynamic> && data.containsKey('items')) {
        rawList = data['items'] as List<dynamic>? ?? [];
      } else if (data is List<dynamic>) {
        rawList = data;
      }

      final dtoList = rawList
          .cast<Map<String, dynamic>>()
          .map(ChapterDto.fromJson);

      // Chuyển đổi sang Domain Model thực tế (mặc định chưa đọc nếu chưa có lịch sử đọc)
      final chapters = dtoList
          .map((dto) => Chapter.fromDto(dto))
          .toList(growable: false);

      return chapters;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      throw AppException(message: 'Không thể xử lý danh sách chương: $e');
    }
  }

  /// 2. Lấy nội dung chi tiết của một chương theo [chapterId]
  Future<ChapterDetail> getChapterDetail(String chapterId) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.chapters}/$chapterId',
      );

      final data = response.data as Map<String, dynamic>;
      final dto = ChapterDetailDto.fromJson(data);
      return ChapterDetail.fromDto(dto);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      throw AppException(message: 'Không thể tải nội dung chương: $e');
    }
  }
}