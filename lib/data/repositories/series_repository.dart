import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_endpoints.dart';
import '../../domain/models/reading_history.dart';
import '../../domain/models/reading_progress.dart';
import '../../domain/models/series.dart';
import '../dtos/bookmark_dto.dart';
import '../dtos/reading_history_dto.dart';
import '../dtos/reading_progress_dto.dart';
import '../dtos/series_dto.dart';
import '../dtos/upsert_reading_progress_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../services/offline_database_service.dart';
import '../services/search_utils.dart';

/// REPOSITORY - Kho lưu trữ dữ liệu
/// Bước 3 trong kiến trúc Compass App:
/// Là lớp trung gian DUY NHẤT kết nối giữa Data Service (Dio/Mạng) và Giao diện (ViewModel).
class SeriesRepository {
  final Dio _dio;
  final OfflineDatabaseService? _offlineDb;

  SeriesRepository(this._dio, {this._offlineDb});

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

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        domainList = domainList
            .where(
              (s) =>
                  SearchUtils.matches(s.title, searchQuery) ||
                  SearchUtils.matches(s.authorName, searchQuery) ||
                  s.genres.any((g) => SearchUtils.matches(g, searchQuery)),
            )
            .toList(growable: false);
      }
      if (genre != null && genre.trim().isNotEmpty) {
        domainList = domainList
            .where(
              (s) => s.genres.any((item) => SearchUtils.matches(item, genre)),
            )
            .toList(growable: false);
      }
      if (status != null) {
        domainList = domainList
            .where((s) => s.status == status)
            .toList(growable: false);
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
        await _dio.delete<void>(ApiEndpoints.libraryBookmarkDelete(seriesId));
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
        if (row is! Map) {
          throw const AppException(
            message: 'Dữ liệu tủ sách không đúng định dạng.',
          );
        }

        final rowMap = Map<String, dynamic>.from(row);
        final bookmark = BookmarkSeriesDto.fromJson(rowMap);
        if (bookmark.seriesId.isEmpty) {
          throw const AppException(
            message: 'Thiếu mã tác phẩm trong dữ liệu tủ sách.',
          );
        }

        final rawSeries = bookmark.series ?? rowMap;
        if (_hasSeriesDetails(rawSeries)) {
          final normalizedJson = Map<String, dynamic>.from(rawSeries)
            ..['id'] = bookmark.seriesId
            ..['title'] =
                rawSeries['title'] ??
                rawSeries['Title'] ??
                rawSeries['seriesTitle'] ??
                rawSeries['SeriesTitle']
            ..['coverImageUrl'] =
                rawSeries['coverImageUrl'] ??
                rawSeries['CoverImageUrl'] ??
                rawSeries['coverUrl'] ??
                rawSeries['CoverUrl']
            ..['authorId'] = rawSeries['authorId'] ?? rawSeries['AuthorId']
            ..['authorName'] =
                rawSeries['authorName'] ??
                rawSeries['AuthorName'] ??
                rawSeries['author'] ??
                rawSeries['Author'];
          final parsedSeries = Series.fromDto(
            SeriesDto.fromJson(normalizedJson),
            isBookmarked: true,
          );
          if (parsedSeries.title == 'Chưa có tiêu đề' ||
              parsedSeries.coverImageUrl.isEmpty) {
            try {
              final details = await getSeriesById(bookmark.seriesId);
              series.add(details.copyWith(isBookmarked: true));
              continue;
            } catch (_) {
              // Nếu lấy chi tiết thất bại hoặc timeout, vẫn giữ lại thông tin cơ bản
            }
          }
          series.add(parsedSeries);
        } else {
          try {
            final details = await getSeriesById(bookmark.seriesId);
            series.add(details.copyWith(isBookmarked: true));
          } catch (_) {
            // Không lấy được chi tiết bổ sung
          }
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

  /// Lấy các bộ truyện đã đọc gần đây cùng thông tin chương và tiến độ nếu API có trả về.
  Future<List<ReadingHistory>> getReadingHistory() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.libraryHistory);
      final rows = _historyRows(response.data);
      final entries = <ReadingHistory>[];

      for (final row in rows) {
        if (row is! Map) {
          throw const AppException(
            message: 'Dữ liệu lịch sử đọc không đúng định dạng.',
          );
        }

        var entry = ReadingHistory.fromDto(
          ReadingHistoryDto.fromJson(Map<String, dynamic>.from(row)),
        );
        if (entry.seriesId.isEmpty) {
          throw const AppException(
            message: 'Thiếu mã tác phẩm trong lịch sử đọc.',
          );
        }
        if (entry.series.title == 'Chưa có tiêu đề' ||
            entry.series.coverImageUrl.isEmpty) {
          try {
            final series = await getSeriesById(entry.seriesId);
            entry = ReadingHistory(
              seriesId: entry.seriesId,
              series: series,
              chapterId: entry.chapterId,
              chapterTitle: entry.chapterTitle,
              chapterNumber: entry.chapterNumber,
              progress: entry.progress,
              lastReadAt: entry.lastReadAt,
            );
          } catch (_) {
            // Nếu lấy chi tiết thất bại hoặc timeout, vẫn giữ lại entry hiện có
          }
        }
        entries.add(entry);
      }

      entries.sort((a, b) {
        final aDate = a.lastReadAt;
        final bDate = b.lastReadAt;
        if (aDate == null) return bDate == null ? 0 : 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      final seenSeries = <String>{};
      return entries
          .where((entry) => seenSeries.add(entry.seriesId))
          .toList(growable: false);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải lịch sử đọc: $e');
    }
  }

  /// Lấy tiến độ hiện tại của một bộ truyện từ Library API.
  Future<double?> getReadingProgress(String seriesId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.libraryProgress,
        queryParameters: {'seriesId': seriesId},
      );
      return ReadingProgressDto.fromJson(response.data).progress;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải tiến độ đọc: $e');
    }
  }

  /// Lấy chi tiết tiến độ đọc (chương + vị trí cuộn) từ Library API.
  /// Trả về null khi tài khoản chưa có tiến độ cho bộ truyện này.
  Future<ReadingProgress?> getReadingProgressDetail(String seriesId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.libraryProgress,
        queryParameters: {'seriesId': seriesId},
      );
      final dto = ReadingProgressDto.fromJson(response.data);
      if (dto.chapterId == null && dto.chapterSortOrder == null) {
        return null;
      }
      return ReadingProgress(
        seriesId: dto.seriesId,
        chapterId: dto.chapterId,
        chapterSortOrder: dto.chapterSortOrder,
        progress: dto.progress ?? 0.0,
        isCompleted: dto.isCompleted ?? false,
        lastReadAtUtc: dto.lastReadAtUtc,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải tiến độ đọc: $e');
    }
  }

  /// Ghi nhận tiến độ đọc hiện tại qua Library API.
  Future<void> updateReadingProgress(UpsertReadingProgressDto progress) async {
    try {
      await _dio.put<void>(
        ApiEndpoints.libraryProgress,
        data: progress.toJson(),
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể cập nhật tiến độ đọc: $e');
    }
  }

  /// Kiểm tra tác phẩm đã được lưu vào tủ sách hay chưa.
  Future<bool> getBookmarkStatus(String seriesId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.libraryBookmarkStatus(seriesId),
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
    if (data is Map) {
      final json = Map<String, dynamic>.from(data);
      for (final key in const [
        'isBookmarked',
        'IsBookmarked',
        'bookmarked',
        'Bookmarked',
        'isSaved',
        'IsSaved',
        'exists',
        'Exists',
        'hasBookmarked',
        'HasBookmarked',
      ]) {
        final val = json[key];
        if (val is bool) return val;
        if (val is num) return val != 0;
        if (val is String) {
          if (val.toLowerCase() == 'true') return true;
          if (val.toLowerCase() == 'false') return false;
        }
      }
      for (final key in const [
        'data',
        'Data',
        'status',
        'Status',
        'result',
        'Result',
      ]) {
        if (json.containsKey(key)) return _parseBookmarkStatus(json[key]);
      }
    }
    throw const AppException(
      message: 'Phản hồi trạng thái tủ sách không đúng định dạng.',
    );
  }

  List<dynamic> _bookmarkRows(dynamic data) {
    if (data == null) return const [];
    if (data is List) return data;
    if (data is Map) {
      final json = Map<String, dynamic>.from(data);
      for (final key in const [
        'items',
        'Items',
        'bookmarks',
        'Bookmarks',
        'results',
        'Results',
        'data',
        'Data',
      ]) {
        final value = json[key];
        if (value is List) return value;
        if (value is Map) {
          return _bookmarkRows(value);
        }
      }
      if (json.containsKey('seriesId') ||
          json.containsKey('SeriesId') ||
          json.containsKey('series') ||
          json.containsKey('Series') ||
          json.containsKey('id') ||
          json.containsKey('Id')) {
        return [json];
      }
    }
    throw const AppException(message: 'Dữ liệu tủ sách không đúng định dạng.');
  }

  List<dynamic> _historyRows(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map) {
      final json = Map<String, dynamic>.from(data);
      for (final key in const [
        'items',
        'Items',
        'history',
        'History',
        'readingHistory',
        'ReadingHistory',
        'results',
        'Results',
        'data',
        'Data',
      ]) {
        final value = json[key];
        if (value is List<dynamic>) return value;
        if (value is Map) return _historyRows(value);
      }
      if (json.containsKey('seriesId') ||
          json.containsKey('SeriesId') ||
          json.containsKey('series') ||
          json.containsKey('Series')) {
        return [json];
      }
    }
    throw const AppException(
      message: 'Dữ liệu lịch sử đọc không đúng định dạng.',
    );
  }

  bool _hasSeriesDetails(Map<String, dynamic> json) {
    final title =
        json['title'] ??
        json['Title'] ??
        json['seriesTitle'] ??
        json['SeriesTitle'];
    return title is String &&
        title.trim().isNotEmpty &&
        title != 'Chưa có tiêu đề';
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
      int? userRating;

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
        // Chưa đăng nhập (401) hoặc chưa đánh giá (404) -> userRating là null
        userRating = null;
      }

      return Series.fromDto(dto).copyWith(
        averageRating: averageRating,
        totalRatings: totalRatings,
        userRating: userRating,
        clearUserRating: userRating == null,
      );
    } on DioException catch (e) {
      if (_offlineDb != null) {
        final offlineRow = await _offlineDb.getDownloadedSeriesRaw(seriesId);
        if (offlineRow != null) {
          List<String> genres = const [];
          final genresStr = offlineRow['genres_json'] as String?;
          if (genresStr != null && genresStr.isNotEmpty) {
            try {
              final decoded = jsonDecode(genresStr);
              if (decoded is List) {
                genres = decoded.map((e) => e.toString()).toList();
              }
            } catch (_) {}
          }
          return Series(
            id: offlineRow['id'] as String,
            title: offlineRow['title'] as String,
            authorName: offlineRow['author_name'] as String,
            description:
                (offlineRow['description'] as String?) ??
                'Chưa có tóm tắt cho tác phẩm này.',
            coverImageUrl: (offlineRow['cover_image_url'] as String?) ?? '',
            status: SeriesStatus.fromInt((offlineRow['status'] as int?) ?? 1),
            genres: genres,
            totalChapters: (offlineRow['total_chapters'] as int?) ?? 0,
          );
        }
      }
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
        data: {'seriesId': seriesId, 'score': score},
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
  final offlineDb = ref.watch(offlineDatabaseServiceProvider);
  return SeriesRepository(dio, offlineDb: offlineDb);
});
