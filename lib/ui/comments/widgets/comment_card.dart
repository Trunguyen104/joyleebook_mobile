import 'package:flutter/material.dart';

import '../../../domain/models/comment.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_avatar.dart';

/// THẺ BÌNH LUẬN ĐỘC GIẢ (CommentCard)
class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    required this.isOwner,
    this.onEdit,
    this.onDelete,
  });

  final Comment comment;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.isNegative || diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(time.day)}/${twoDigits(time.month)}/${time.year}';
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space3),
      padding: const EdgeInsets.all(AppDimensions.space3),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: colors.borderDefault.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Username, Thời gian, Menu thao tác (nếu là chủ sở hữu)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              JoyleeAvatar(
                initials: _getInitials(comment.username),
                size: JoyleeAvatarSize.sm,
              ),
              const SizedBox(width: AppDimensions.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.username,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _formatTime(comment.createdAt),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (comment.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• (Đã chỉnh sửa)',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontStyle: FontStyle.italic,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Menu thao tác nếu là chủ sở hữu bình luận
              if (isOwner)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  tooltip: 'Tùy chọn bình luận',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      _confirmDelete(context, colors);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: colors.textPrimary,
                          ),
                          const SizedBox(width: AppDimensions.space2),
                          const Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: colors.danger,
                          ),
                          const SizedBox(width: AppDimensions.space2),
                          Text('Xóa', style: TextStyle(color: colors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: AppDimensions.space2),

          // Nội dung bình luận
          Text(
            comment.content,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic colors) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa bình luận'),
        content: const Text('Bạn có chắc chắn muốn xóa bình luận này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.danger),
            onPressed: () {
              Navigator.of(dialogCtx).pop(true);
              onDelete?.call();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
