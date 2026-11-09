import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/comment_repository.dart';
import '../../../domain/models/comment.dart';

/// THAM SỐ TRUY VẤN BÌNH LUẬN (theo bộ truyện hoặc theo chương)
@immutable
class CommentsQuery {
  final String? seriesId;
  final String? chapterId;

  const CommentsQuery({this.seriesId, this.chapterId})
    : assert(
        seriesId != null || chapterId != null,
        'Phải cung cấp ít nhất seriesId hoặc chapterId để tải bình luận.',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentsQuery &&
          runtimeType == other.runtimeType &&
          seriesId == other.seriesId &&
          chapterId == other.chapterId;

  @override
  int get hashCode => Object.hash(seriesId, chapterId);
}

/// RIVERPOD PROVIDER: Quản lý danh sách bình luận theo query
final commentsViewModelProvider =
    AsyncNotifierProvider.family<
      CommentsViewModel,
      PagedComments,
      CommentsQuery
    >(CommentsViewModel.new, retry: (retryCount, error) => null);

/// VIEWMODEL: Quản lý nghiệp vụ xem, gửi, sửa và xóa bình luận
class CommentsViewModel extends AsyncNotifier<PagedComments> {
  final CommentsQuery query;

  CommentsViewModel(this.query);

  @override
  Future<PagedComments> build() async {
    return _fetchComments(page: 1);
  }

  Future<PagedComments> _fetchComments({int page = 1}) {
    return ref
        .read(commentRepositoryProvider)
        .getComments(
          seriesId: query.seriesId,
          chapterId: query.chapterId,
          page: page,
          pageSize: 20,
        );
  }

  /// Làm mới danh sách bình luận (Pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchComments(page: 1));
  }

  /// Tải thêm bình luận (Phân trang khi cuộn xuống cuối)
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.page >= current.totalPages) return;

    try {
      final nextPage = await _fetchComments(page: current.page + 1);
      final existingIds = current.items.map((c) => c.id).toSet();
      final newUniqueItems = nextPage.items
          .where((c) => !existingIds.contains(c.id))
          .toList();

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...newUniqueItems],
          page: nextPage.page,
          totalPages: nextPage.totalPages,
          totalCount: nextPage.totalCount,
        ),
      );
    } catch (_) {
      // Giữ nguyên dữ liệu hiện tại khi tải trang kế tiếp lỗi
    }
  }

  /// Gửi bình luận mới
  Future<bool> createComment({
    required String seriesId,
    required String chapterId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    try {
      final created = await ref
          .read(commentRepositoryProvider)
          .createComment(
            seriesId: seriesId,
            chapterId: chapterId,
            content: trimmed,
          );

      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            items: [created, ...current.items],
            totalCount: current.totalCount + 1,
          ),
        );
      } else {
        await refresh();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Chỉnh sửa nội dung bình luận
  Future<bool> updateComment({
    required String commentId,
    required String newContent,
  }) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty) return false;

    try {
      final updated = await ref
          .read(commentRepositoryProvider)
          .updateComment(commentId: commentId, content: trimmed);

      final current = state.value;
      if (current != null) {
        final newItems = current.items
            .map((c) => c.id == commentId ? updated : c)
            .toList();
        state = AsyncData(current.copyWith(items: newItems));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Xóa bình luận (Optimistic UI kèm Rollback)
  Future<bool> deleteComment(String commentId) async {
    final current = state.value;
    if (current == null) return false;

    final original = current;
    // BƯỚC 1: Xóa lạc quan trên UI ngay lập tức
    final newItems = current.items.where((c) => c.id != commentId).toList();
    final newTotal = (current.totalCount - 1).clamp(0, 999999);
    state = AsyncData(current.copyWith(items: newItems, totalCount: newTotal));

    // BƯỚC 2: Gửi request lên server
    try {
      await ref.read(commentRepositoryProvider).deleteComment(commentId);
      return true;
    } catch (_) {
      // BƯỚC 3: Phục hồi lại bình luận nếu server lỗi
      state = AsyncData(original);
      return false;
    }
  }
}
