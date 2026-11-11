import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import 'comments_list_view.dart';

/// MODAL BOTTOM SHEET BÌNH LUẬN TRONG TRÌNH ĐỌC (ChapterCommentsSheet)
class ChapterCommentsSheet extends StatelessWidget {
  const ChapterCommentsSheet({
    super.key,
    required this.seriesId,
    required this.chapterId,
    required this.chapterTitle,
    required this.sortOrder,
  });

  final String seriesId;
  final String chapterId;
  final String chapterTitle;
  final int sortOrder;

  static Future<void> show(
    BuildContext context, {
    required String seriesId,
    required String chapterId,
    required String chapterTitle,
    required int sortOrder,
  }) {
    final colors = context.colors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ChapterCommentsSheet(
          seriesId: seriesId,
          chapterId: chapterId,
          chapterTitle: chapterTitle,
          sortOrder: sortOrder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        // Thanh kéo (Drag Handle)
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: AppDimensions.space2),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header Tiêu đề
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.space4,
            AppDimensions.space2,
            AppDimensions.space2,
            AppDimensions.space2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bình luận Chương $sortOrder',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      chapterTitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                tooltip: 'Đóng',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Danh sách bình luận của chương này
        Expanded(
          child: CommentsListView(seriesId: seriesId, chapterId: chapterId),
        ),
      ],
    );
  }
}
