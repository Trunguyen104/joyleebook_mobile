import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/chapter.dart';
import '../../../domain/models/downloaded_series.dart';
import '../../../domain/models/series.dart';
import '../../../routing/app_paths.dart';
import '../../chapter/widgets/chapter_item.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/downloaded_series_view_model.dart';
import '../view_models/offline_series_detail_view_model.dart';

/// MÀN HÌNH CHI TIẾT TÁC PHẨM NGOẠI TUYẾN GIẢN LƯỢC (OfflineSeriesDetailScreen)
/// Thiết kế tinh gọn dành riêng cho chế độ Offline:
/// - Không hiển thị đánh giá (Rating), không có tab Bình luận, không có nút Bookmark online.
/// - Chỉ nạp dữ liệu từ SQLite cục bộ và ảnh bìa lưu trên thiết bị.
/// - Giữ trọn vẹn bố cục Warm Editorial: Header (Bìa, Tên, Tác giả, Badge Ngoại tuyến),
///   Nút Đọc ngay / Đọc tiếp, và 2 Tab: Tóm tắt & Chương.
class OfflineSeriesDetailScreen extends ConsumerWidget {
  const OfflineSeriesDetailScreen({
    super.key,
    required this.seriesId,
    this.initialSeries,
  });

  final String seriesId;
  final DownloadedSeries? initialSeries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final detailAsync = ref.watch(
      offlineSeriesDetailViewModelProvider(seriesId),
    );

    if (detailAsync.hasError) {
      return Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(title: const Text('Lỗi tải tác phẩm')),
        body: JoyleeErrorView(
          message: 'Không thể đọc dữ liệu ngoại tuyến từ bộ nhớ.',
          onRetry: () => ref
              .read(offlineSeriesDetailViewModelProvider(seriesId).notifier)
              .refresh(),
        ),
      );
    }

    final data = detailAsync.value;
    final series = data?.series ?? initialSeries;
    final chapters = data?.chapters ?? const <Chapter>[];

    if (detailAsync.isLoading && series == null) {
      return Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryBrand),
          ),
        ),
      );
    }

    if (series == null) {
      return Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(title: const Text('Không tìm thấy bản tải')),
        body: JoyleeEmptyState(
          iconData: Icons.cloud_off_rounded,
          title: 'Bản tải không tồn tại',
          message: 'Tác phẩm này đã bị xóa khỏi bộ nhớ ngoại tuyến.',
          actionLabel: 'Quay lại',
          onAction: () => context.pop(),
        ),
      );
    }

    return _buildContent(context, ref, colors, series, chapters);
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
    DownloadedSeries series,
    List<Chapter> chapters,
  ) {
    Chapter? activeChapter;
    for (final c in chapters) {
      if (c.isActive) {
        activeChapter = c;
        break;
      }
    }

    final readButtonLabel = activeChapter != null
        ? 'Đọc tiếp Ch. ${activeChapter.sortOrder}'
        : 'Đọc ngay';

    final chapterCountLabel = chapters.isNotEmpty
        ? chapters.length
        : series.downloadedChaptersCount;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          title: Text(
            series.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: colors.danger),
              tooltip: 'Xóa bản tải',
              onPressed: () => _confirmDelete(context, ref, series),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.space4,
                  AppDimensions.space2,
                  AppDimensions.space4,
                  AppDimensions.space3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(colors, series),
                    const SizedBox(height: AppDimensions.space4),
                    JoyleeButton(
                      label: readButtonLabel,
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      onPressed: chapters.isEmpty
                          ? null
                          : () => _openChapter(
                              context,
                              series,
                              activeChapter ?? chapters.first,
                            ),
                    ),
                    const SizedBox(height: AppDimensions.space2),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _OfflineTabBarDelegate(
                TabBar(
                  indicatorColor: colors.primaryBrand,
                  labelColor: colors.primaryBrand,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  indicatorWeight: 3,
                  tabs: [
                    const Tab(text: 'Tóm tắt'),
                    Tab(text: 'Chương ($chapterCountLabel)'),
                  ],
                ),
                backgroundColor: colors.bgCanvas,
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildOverviewTab(colors, series),
              _buildChaptersTab(context, colors, series, chapters),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors, DownloadedSeries series) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 110,
          height: 158,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: colors.borderDefault.withValues(alpha: 0.6),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: _buildCoverImage(colors, series),
          ),
        ),
        const SizedBox(width: AppDimensions.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Ngoại tuyến + Dung lượng
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primaryBrand.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.offline_pin_rounded,
                      size: 13,
                      color: colors.primaryBrand,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ngoại tuyến • ${series.formattedSize}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryBrand,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space2),
              Text(
                series.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.space2),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      series.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space2),
              Text(
                series.status.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: series.status == SeriesStatus.completed
                      ? colors.success
                      : colors.primaryBrand,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverImage(AppColors colors, DownloadedSeries series) {
    if (!kIsWeb && series.coverLocalPath != null) {
      final file = File(series.coverLocalPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    if (series.coverImageUrl.isNotEmpty) {
      return Image.network(
        series.coverImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _coverPlaceholder(colors),
      );
    }
    return _coverPlaceholder(colors);
  }

  Widget _coverPlaceholder(AppColors colors) {
    return Container(
      color: colors.bgSurfaceSubtle,
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: 38,
          color: colors.textDisabled,
        ),
      ),
    );
  }

  Widget _buildOverviewTab(AppColors colors, DownloadedSeries series) {
    final downloadedDate =
        '${series.downloadedAt.day.toString().padLeft(2, '0')}/'
        '${series.downloadedAt.month.toString().padLeft(2, '0')}/'
        '${series.downloadedAt.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin bản tải offline
          Container(
            padding: const EdgeInsets.all(AppDimensions.space3),
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoTile(
                  label: 'Đã tải',
                  value: '${series.downloadedChaptersCount} chương',
                ),
                _InfoTile(label: 'Dung lượng', value: series.formattedSize),
                _InfoTile(label: 'Ngày tải', value: downloadedDate),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space4),

          if (series.genres.isNotEmpty) ...[
            Text(
              'Thể loại',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: series.genres
                  .map(
                    (g) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgSurfaceSubtle,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
                        border: Border.all(color: colors.borderDefault),
                      ),
                      child: Text(
                        g,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppDimensions.space4),
          ],

          Text(
            'Giới thiệu nội dung',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.space2),
          Text(
            series.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersTab(
    BuildContext context,
    AppColors colors,
    DownloadedSeries series,
    List<Chapter> chapters,
  ) {
    if (chapters.isEmpty) {
      return const JoyleeEmptyState(
        iconData: Icons.format_list_bulleted_rounded,
        title: 'Chưa có chương nào được lưu',
        message: 'Bản tải của bộ truyện này hiện chưa có nội dung chương.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space2),
      itemCount: chapters.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: colors.borderDefault.withValues(alpha: 0.4),
        indent: AppDimensions.space4,
        endIndent: AppDimensions.space4,
      ),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return ChapterItem(
          chapter: chapter,
          onTap: () => _openChapter(context, series, chapter),
        );
      },
    );
  }

  void _openChapter(
    BuildContext context,
    DownloadedSeries series,
    Chapter chapter,
  ) {
    context.push(
      AppPaths.chapterReader(series.id, chapter.id, isOffline: true),
      extra: series.title,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DownloadedSeries series,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa bản tải?'),
        content: Text(
          'Bạn có chắc muốn xóa bản tải của tác phẩm "${series.title}"?\n'
          'Dữ liệu đọc ngoại tuyến (${series.formattedSize}) sẽ được xóa khỏi thiết bị.',
        ),
        actions: [
          JoyleeButton(
            label: 'Hủy',
            variant: JoyleeButtonVariant.ghost,
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          JoyleeButton(
            label: 'Xóa bản tải',
            variant: JoyleeButtonVariant.danger,
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await ref
          .read(downloadedSeriesViewModelProvider.notifier)
          .deleteSeries(series.id);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Đã xóa bản tải "${series.title}"')),
        );
        context.pop();
      }
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _OfflineTabBarDelegate extends SliverPersistentHeaderDelegate {
  _OfflineTabBarDelegate(this._tabBar, {required this.backgroundColor});

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_OfflineTabBarDelegate oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor;
  }
}
