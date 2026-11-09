import 'package:joyleebook_mobile/data/repositories/comment_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/comment.dart';

/// FAKE COMMENT REPOSITORY - Giả lập kho dữ liệu bình luận trong RAM để test
class FakeCommentRepository implements CommentRepository {
  final List<Comment> _comments;
  bool shouldThrowError;

  FakeCommentRepository({
    List<Comment>? initialComments,
    this.shouldThrowError = false,
  }) : _comments = initialComments != null ? List.of(initialComments) : [];

  @override
  Future<PagedComments> getComments({
    String? seriesId,
    String? chapterId,
    int page = 1,
    int pageSize = 10,
  }) async {
    if (shouldThrowError) {
      throw AppException(message: 'Lỗi tải bình luận từ máy chủ.');
    }

    var filtered = _comments.where((c) {
      if (chapterId != null && chapterId.isNotEmpty) {
        return c.chapterId == chapterId;
      }
      if (seriesId != null && seriesId.isNotEmpty) {
        return c.seriesId == seriesId;
      }
      return true;
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalCount = filtered.length;
    final totalPages = (totalCount / pageSize).ceil();
    final start = (page - 1) * pageSize;
    final items = start < totalCount
        ? filtered.sublist(start, (start + pageSize).clamp(0, totalCount))
        : <Comment>[];

    return PagedComments(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: totalPages > 0 ? totalPages : 1,
    );
  }

  @override
  Future<Comment> createComment({
    required String seriesId,
    required String chapterId,
    required String content,
  }) async {
    if (shouldThrowError) {
      throw AppException(message: 'Không thể gửi bình luận.');
    }

    final comment = Comment(
      id: 'comment-${DateTime.now().millisecondsSinceEpoch}',
      seriesId: seriesId,
      chapterId: chapterId,
      userId: 'test-user-id',
      username: 'test_user',
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isEdited: false,
    );
    _comments.insert(0, comment);
    return comment;
  }

  @override
  Future<Comment> updateComment({
    required String commentId,
    required String content,
  }) async {
    if (shouldThrowError) {
      throw AppException(message: 'Không thể cập nhật bình luận.');
    }

    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) {
      throw AppException(message: 'Bình luận không tồn tại.');
    }

    final updated = _comments[index].copyWith(
      content: content,
      updatedAt: DateTime.now(),
      isEdited: true,
    );
    _comments[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    if (shouldThrowError) {
      throw AppException(message: 'Không thể xóa bình luận.');
    }

    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) {
      throw AppException(message: 'Bình luận không tồn tại.');
    }
    _comments.removeAt(index);
  }
}
