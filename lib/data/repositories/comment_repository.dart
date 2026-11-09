import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_endpoints.dart';
import '../../domain/models/comment.dart';
import '../dtos/comment_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';

/// RIVERPOD PROVIDER: Đăng ký CommentRepository
final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return CommentRepository(dio);
});

/// REPOSITORY: Quản lý dữ liệu bình luận từ Community Service
class CommentRepository {
  final Dio _dio;

  CommentRepository(this._dio);

  /// 1. Lấy danh sách bình luận (theo bộ truyện hoặc theo chương)
  Future<PagedComments> getComments({
    String? seriesId,
    String? chapterId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
      if (seriesId != null && seriesId.isNotEmpty) {
        queryParams['seriesId'] = seriesId;
      }
      if (chapterId != null && chapterId.isNotEmpty) {
        queryParams['chapterId'] = chapterId;
      }

      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.comments,
        queryParameters: queryParams,
      );

      final data = response.data ?? {};
      final dto = PagedCommentsDto.fromJson(data);
      return PagedComments.fromDto(dto);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải danh sách bình luận: $e');
    }
  }

  /// 2. Gửi bình luận mới
  Future<Comment> createComment({
    required String seriesId,
    required String chapterId,
    required String content,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.comments,
        data: {
          'seriesId': seriesId,
          'chapterId': chapterId,
          'content': content.trim(),
        },
      );

      final data = response.data ?? {};
      final dto = CommentDto.fromJson(data);
      return Comment.fromDto(dto);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể gửi bình luận: $e');
    }
  }

  /// 3. Chỉnh sửa bình luận đã gửi
  Future<Comment> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.commentDetail(commentId),
        data: {'content': content.trim()},
      );

      final data = response.data ?? {};
      final dto = CommentDto.fromJson(data);
      return Comment.fromDto(dto);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể cập nhật bình luận: $e');
    }
  }

  /// 4. Xóa bình luận
  Future<void> deleteComment(String commentId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.commentDetail(commentId));
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể xóa bình luận: $e');
    }
  }
}
