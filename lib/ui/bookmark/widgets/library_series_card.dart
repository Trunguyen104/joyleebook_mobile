import 'package:flutter/material.dart';

import '../../../domain/models/reading_history.dart';
import '../../../domain/models/series.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import 'reading_progress_view.dart';

class LibrarySeriesCard extends StatelessWidget {
  const LibrarySeriesCard({
    super.key,
    required this.series,
    required this.onTap,
    this.history,
    this.onRemoveBookmark,
    this.isBookmarkActionLoading = false,
  });

  final Series series;
  final ReadingHistory? history;
  final VoidCallback onTap;
  final VoidCallback? onRemoveBookmark;
  final bool isBookmarkActionLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chapterLabel = _chapterLabel;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 108,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      child: series.coverImageUrl.isEmpty
                          ? _buildCoverPlaceholder(colors)
                          : Image.network(
                              series.coverImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildCoverPlaceholder(colors),
                            ),
                    ),
                    if (onRemoveBookmark != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Material(
                          color: colors.bgSurface.withValues(alpha: 0.92),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Bỏ lưu',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: AppDimensions.minTouchTarget,
                              height: AppDimensions.minTouchTarget,
                            ),
                            onPressed: isBookmarkActionLoading
                                ? null
                                : onRemoveBookmark,
                            icon: isBookmarkActionLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.bookmark_rounded,
                                    color: colors.primaryBrand,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space2),
              Text(
                series.title.trim().isEmpty ? 'Chưa có tiêu đề' : series.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                chapterLabel ?? 'Đã lưu trong tủ sách',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.space1),
              if (history != null)
                ReadingProgressView(
                  seriesId: series.id,
                  progress: history!.progress,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _chapterLabel {
    if (history == null) return null;
    final title = history!.chapterTitle?.trim();
    final number = history!.chapterNumber;
    if (title != null && title.isNotEmpty) {
      return number == null ? title : 'Ch. $number · $title';
    }
    return number == null ? null : 'Chương $number';
  }

  Widget _buildCoverPlaceholder(AppColors colors) => ColoredBox(
    color: colors.bgSurfaceSubtle,
    child: Center(
      child: Icon(
        Icons.auto_stories_rounded,
        size: 32,
        color: colors.textDisabled,
      ),
    ),
  );
}
