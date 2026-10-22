import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_endpoints.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/chapter_detail.dart';
import '../dtos/chapter_detail_dto.dart';
import '../dtos/chapter_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../services/reading_preferences_service.dart';

/// RIVERPOD PROVIDER: Đăng ký ChapterRepository
final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final readingPrefs = ref.watch(readingPreferencesServiceProvider);
  return ChapterRepository(dio, readingPrefs);
});

/// REPOSITORY - Kho lưu trữ dữ liệu chương truyện
class ChapterRepository {
  final Dio _dio;
  final ReadingPreferencesService? _readingPrefs;

  ChapterRepository(this._dio, [this._readingPrefs]);

  /// 1. Lấy danh sách chương của một bộ truyện theo [seriesId]
  /// Tự động nạp tiến độ đọc gần nhất từ Local Storage để gán cờ isActive và readPercentage.
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

      // Đọc tiến độ gần nhất từ Local Storage (nếu có)
      final lastProgress = await _readingPrefs?.getLastReadProgress(seriesId);

      // Chuyển đổi sang Domain Model thực tế kèm trạng thái đang đọc (isActive)
      final chapters = dtoList.map((dto) {
        final isMatch = lastProgress != null &&
            (lastProgress.chapterId == dto.id ||
                lastProgress.sortOrder == dto.sortOrder);
        return Chapter.fromDto(
          dto,
          isActive: isMatch,
          readPercentage: isMatch ? lastProgress.readPercentage : 0.0,
          isCompleted:
              lastProgress != null && dto.sortOrder < lastProgress.sortOrder,
        );
      }).toList(growable: false);

      return chapters;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
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
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải nội dung chương: $e');
    }
  }
}
