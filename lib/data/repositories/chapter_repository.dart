import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_endpoints.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/chapter_detail.dart';
import '../dtos/chapter_detail_dto.dart';
import '../dtos/chapter_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../services/offline_database_service.dart';

/// RIVERPOD PROVIDER: Đăng ký ChapterRepository
final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final offlineDb = ref.watch(offlineDatabaseServiceProvider);
  return ChapterRepository(dio, offlineDb: offlineDb);
});

/// REPOSITORY - Kho lưu trữ dữ liệu chương truyện
class ChapterRepository {
  final Dio _dio;
  final OfflineDatabaseService? _offlineDb;

  ChapterRepository(this._dio, {this._offlineDb});

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

      return rawList
          .cast<Map<String, dynamic>>()
          .map((json) => Chapter.fromDto(ChapterDto.fromJson(json)))
          .toList(growable: false);
    } on DioException catch (e) {
      if (_offlineDb != null) {
        final offlineRows = await _offlineDb.getDownloadedChaptersRaw(seriesId);
        if (offlineRows.isNotEmpty) {
          return offlineRows
              .map(
                (row) => Chapter(
                  id: row['id'] as String,
                  seriesId: row['series_id'] as String,
                  sortOrder: (row['sort_order'] as int?) ?? 1,
                  title: row['title'] as String,
                  isFree: ((row['is_free'] as int?) ?? 1) == 1,
                  durationMinutes: (row['duration_minutes'] as int?) ?? 15,
                ),
              )
              .toList(growable: false);
        }
      }
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể xử lý danh sách chương: $e');
    }
  }

  /// 2. Lấy nội dung chi tiết của một chương theo [chapterId]
  Future<ChapterDetail> getChapterDetail(String chapterId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.chapters}/$chapterId');

      final data = response.data as Map<String, dynamic>;
      final dto = ChapterDetailDto.fromJson(data);
      return ChapterDetail.fromDto(dto);
    } on DioException catch (e) {
      if (_offlineDb != null) {
        final offlineRow = await _offlineDb.getDownloadedChapterDetailRaw(
          chapterId,
        );
        if (offlineRow != null) {
          final publishedAtStr = offlineRow['published_at'] as String?;
          return ChapterDetail(
            id: offlineRow['id'] as String,
            seriesId: offlineRow['series_id'] as String,
            title: offlineRow['title'] as String,
            content: offlineRow['content'] as String,
            sortOrder: (offlineRow['sort_order'] as int?) ?? 1,
            totalChapters: (offlineRow['total_chapters'] as int?) ?? 0,
            status: (offlineRow['status'] as int?) ?? 1,
            publishedAt: publishedAtStr != null
                ? DateTime.tryParse(publishedAtStr)
                : null,
            isOffline: true,
          );
        }
      }
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải nội dung chương: $e');
    }
  }
}
