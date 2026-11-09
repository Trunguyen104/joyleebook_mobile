import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/chapter.dart';
import '../../../domain/models/comment.dart';
import '../../auth/view_models/auth_session_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/comments_view_model.dart';
import 'comment_card.dart';
import 'comment_input_box.dart';

/// DANH SÁCH BÌNH LUẬN (CommentsListView)
/// Tuân thủ quy chuẩn 4 trạng thái và hỗ trợ phân trang, gửi, sửa, xóa bình luận
class CommentsListView extends ConsumerStatefulWidget {
  const CommentsListView({
    super.key,
    required this.seriesId,
    this.chapterId,
    this.availableChapters,
    this.scrollController,
  });

  final String seriesId;
  final String? chapterId;
  final List<Chapter>? availableChapters;
  final ScrollController? scrollController;

  @override
  ConsumerState<CommentsListView> createState() => _CommentsListViewState();
}

class _CommentsListViewState extends ConsumerState<CommentsListView> {
  late final ScrollController _scrollController;
  late final bool _internalController;
  Comment? _editingComment;
  String? _selectedChapterId;

  CommentsQuery get _query =>
      CommentsQuery(seriesId: widget.seriesId, chapterId: widget.chapterId);

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
      _internalController = false;
    } else {
      _scrollController = ScrollController();
      _internalController = true;
    }
    _scrollController.addListener(_onScroll);

    // Mặc định chọn chapter đầu tiên nếu có danh sách chapter và chưa chỉ định chapterId
    if (widget.chapterId != null) {
      _selectedChapterId = widget.chapterId;
    } else if (widget.availableChapters != null &&
        widget.availableChapters!.isNotEmpty) {
      _selectedChapterId = widget.availableChapters!.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant CommentsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chapterId != oldWidget.chapterId) {
      _selectedChapterId = widget.chapterId;
    } else if (_selectedChapterId == null &&
        widget.availableChapters != null &&
        widget.availableChapters!.isNotEmpty) {
      _selectedChapterId = widget.availableChapters!.first.id;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_internalController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(commentsViewModelProvider(_query).notifier).loadMore();
    }
  }

  Future<bool> _handleSubmit(String content) async {
    final notifier = ref.read(commentsViewModelProvider(_query).notifier);

    // Nếu đang trong chế độ chỉnh sửa
    if (_editingComment != null) {
      final success = await notifier.updateComment(
        commentId: _editingComment!.id,
        newContent: content,
      );
      if (!mounted) return false;

      if (success) {
        setState(() => _editingComment = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật bình luận')));
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật bình luận. Vui lòng thử lại.'),
          ),
        );
        return false;
      }
    }

    // Gửi bình luận mới
    final targetChapterId = widget.chapterId ?? _selectedChapterId;
    if (targetChapterId == null || targetChapterId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn chương muốn bình luận.')),
      );
      return false;
    }

    final success = await notifier.createComment(
      seriesId: widget.seriesId,
      chapterId: targetChapterId,
      content: content,
    );
    if (!mounted) return false;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi bình luận thành công!')),
      );
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể gửi bình luận. Vui lòng thử lại sau.'),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authSession = ref.watch(authSessionProvider).value;
    final currentUserId = authSession?.userId;
    final isSignedIn = authSession != null;

    final commentsAsync = ref.watch(commentsViewModelProvider(_query));

    return Column(
      children: [
        // Thanh chọn chương khi ở cấp bộ truyện (nếu có nhiều chương)
        if (widget.chapterId == null &&
            widget.availableChapters != null &&
            widget.availableChapters!.isNotEmpty)
          _buildChapterSelector(colors),

        // Thân danh sách bình luận (4 trạng thái)
        Expanded(
          child: commentsAsync.when(
            // 1. Loading
            loading: () => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colors.primaryBrand),
              ),
            ),

            // 2. Error
            error: (error, _) => JoyleeErrorView(
              message: error.toString(),
              onRetry: () => ref
                  .read(commentsViewModelProvider(_query).notifier)
                  .refresh(),
            ),

            // 3 & 4. Data / Empty
            data: (paged) {
              if (paged.items.isEmpty) {
                return RefreshIndicator(
                  color: colors.primaryBrand,
                  onRefresh: () => ref
                      .read(commentsViewModelProvider(_query).notifier)
                      .refresh(),
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: AppDimensions.space6),
                      JoyleeEmptyState(
                        iconData: Icons.chat_bubble_outline_rounded,
                        title: 'Chưa có bình luận nào',
                        message: 'Hãy là người đầu tiên chia sẻ cảm nghĩ về tác phẩm này nhé!',
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: colors.primaryBrand,
                onRefresh: () => ref
                    .read(commentsViewModelProvider(_query).notifier)
                    .refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.space4),
                  itemCount:
                      paged.items.length +
                      (paged.page < paged.totalPages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == paged.items.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.space3,
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.primaryBrand,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final comment = paged.items[index];
                    final isOwner =
                        currentUserId != null &&
                        comment.userId == currentUserId;

                    return CommentCard(
                      key: ValueKey(comment.id),
                      comment: comment,
                      isOwner: isOwner,
                      onEdit: () {
                        setState(() => _editingComment = comment);
                      },
                      onDelete: () async {
                        final notifier = ref.read(
                          commentsViewModelProvider(_query).notifier,
                        );
                        final success = await notifier.deleteComment(
                          comment.id,
                        );
                        if (!context.mounted) return;
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Xóa bình luận thất bại. Vui lòng thử lại.',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xóa bình luận.')),
                          );
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Ô nhập bình luận phía dưới
        CommentInputBox(
          isSignedIn: isSignedIn,
          initialText: _editingComment?.content,
          isEditing: _editingComment != null,
          onCancelEdit: () {
            setState(() => _editingComment = null);
          },
          onSubmit: _handleSubmit,
        ),
      ],
    );
  }

  Widget _buildChapterSelector(dynamic colors) {
    final chapters = widget.availableChapters!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: colors.bgCanvas,
        border: Border(bottom: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, size: 16, color: colors.textSecondary),
          const SizedBox(width: AppDimensions.space2),
          Text(
            'Bình luận cho:',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppDimensions.space2),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedChapterId,
                isDense: true,
                isExpanded: true,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                dropdownColor: colors.bgSurface,
                items: chapters.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(
                      'Chương ${c.sortOrder}: ${c.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedChapterId = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
