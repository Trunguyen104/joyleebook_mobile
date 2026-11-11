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

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCover(colors),
            const SizedBox(width: AppDimensions.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title.trim().isEmpty
                        ? 'Chưa có tiêu đề'
                        : series.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space1),
                  Text(
                    series.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppDimensions.space2),
                  _buildMetadata(colors),
                  const SizedBox(height: AppDimensions.space2),
                  Wrap(
                    spacing: AppDimensions.space1,
                    runSpacing: AppDimensions.space1,
                    children: [
                      for (final genre in _displayGenres)
                        _buildTag(genre, colors),
                    ],
                  ),
                  if (history != null) ...[
                    const SizedBox(height: AppDimensions.space1),
                    if (_chapterLabel != null)
                      Text(
                        _chapterLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ReadingProgressView(
                      seriesId: series.id,
                      progress: history!.progress,
                    ),
                  ],
                ],
              ),
            ),
            if (onRemoveBookmark != null) ...[
              const SizedBox(width: AppDimensions.space1),
              SizedBox(
                width: AppDimensions.minTouchTarget,
                height: AppDimensions.minTouchTarget,
                child: IconButton(
                  tooltip: 'Bỏ lưu',
                  onPressed: isBookmarkActionLoading ? null : onRemoveBookmark,
                  icon: isBookmarkActionLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.bookmark_rounded,
                          color: colors.primaryBrand,
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCover(AppColors colors) {
    return Container(
      width: 76,
      height: 110,
      decoration: BoxDecoration(
        color: colors.bgSurfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: series.coverImageUrl.isEmpty
          ? _buildCoverPlaceholder(colors)
          : Image.network(
              series.coverImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildCoverPlaceholder(colors),
            ),
    );
  }

  Widget _buildMetadata(AppColors colors) {
    final hasViews = series.viewCount != null;
    final hasRating = series.averageRating > 0;
    final hasChapters = series.totalChapters > 0;

    return Wrap(
      spacing: AppDimensions.space2,
      runSpacing: AppDimensions.space1,
      children: [
        if (hasViews)
          _metadataItem(
            icon: Icons.remove_red_eye_outlined,
            label: _formatViews(series.viewCount!),
            colors: colors,
          ),
        if (hasChapters)
          _metadataItem(
            icon: Icons.format_list_bulleted_rounded,
            label: '${series.totalChapters} chương',
            colors: colors,
          )
        else if (hasRating)
          _metadataItem(
            icon: Icons.star_rounded,
            label: series.averageRating.toStringAsFixed(1),
            colors: colors,
            iconColor: colors.accent,
          ),
      ],
    );
  }

  Widget _metadataItem({
    required IconData icon,
    required String label,
    required AppColors colors,
    Color? iconColor,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: iconColor ?? colors.textSecondary),
      const SizedBox(width: AppDimensions.space1),
      Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
    ],
  );

  Widget _buildTag(String label, AppColors colors) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: colors.bgSurfaceSubtle,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    ),
  );

  List<String> get _displayGenres => series.genres.isNotEmpty
      ? series.genres.take(3).map(_capitalizeGenre).toList()
      : [series.status.label];

  String _capitalizeGenre(String raw) => raw
      .trim()
      .split(' ')
      .map((word) {
        if (word.isEmpty) return '';
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');

  String _formatViews(int views) {
    if (views >= 1000000) return '${(views / 1000000).toStringAsFixed(1)}M';
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return '$views';
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
