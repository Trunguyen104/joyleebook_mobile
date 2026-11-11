import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/downloaded_series.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/downloaded_series_view_model.dart';

/// MÀN HÌNH DANH SÁCH TRUYỆN ĐÃ TẢI NGOẠI TUYẾN (DownloadedSeriesScreen)
/// Đảm bảo đủ 4 trạng thái: Loading, Empty, Error, Data.
class DownloadedSeriesScreen extends ConsumerWidget {
  const DownloadedSeriesScreen({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(title: const Text('Truyện đã tải về')),
      body: DownloadedSeriesListView(onExplore: onExplore),
    );
  }
}

/// WIDGET DÙNG CHUNG - Nội dung danh sách truyện đã tải (dùng trong Tab "Đã tải" của Tủ sách & DownloadedSeriesScreen)
class DownloadedSeriesListView extends ConsumerWidget {
  const DownloadedSeriesListView({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedAsync = ref.watch(downloadedSeriesViewModelProvider);

    return downloadedAsync.when(
      // TRẠNG THÁI 1: LOADING
      loading: () => const Center(child: CircularProgressIndicator()),

      // TRẠNG THÁI 2: ERROR
      error: (error, _) => JoyleeErrorView(
        message: 'Không thể tải danh sách truyện ngoại tuyến: $error',
        onRetry: () =>
            ref.read(downloadedSeriesViewModelProvider.notifier).refresh(),
      ),

      // TRẠNG THÁI 3 & 4: EMPTY & DATA
      data: (seriesList) {
        if (seriesList.isEmpty) {
          return JoyleeEmptyState(
            iconData: Icons.cloud_download_outlined,
            title: 'Chưa có truyện đã tải',
            message: 'Tải trọn bộ tác phẩm yêu thích để bạn có thể đọc mọi lúc mọi nơi ngay cả khi không có kết nối mạng.',
            actionLabel: 'Khám phá truyện',
            onAction: onExplore ?? () => context.go(AppPaths.series),
          );
        }

        final totalBytesFormatted = ref
            .read(downloadedSeriesViewModelProvider.notifier)
            .formattedTotalBytes;

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(downloadedSeriesViewModelProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space4,
              vertical: AppDimensions.space3,
            ),
            children: [
              // Thanh thông tin dung lượng + nút xóa tất cả
              _StorageInfoBar(
                count: seriesList.length,
                formattedTotalSize: totalBytesFormatted,
                onDeleteAll: () => _confirmDeleteAll(context, ref),
              ),
              const SizedBox(height: AppDimensions.space3),

              // Danh sách truyện đã tải
              ...seriesList.map(
                (series) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space3),
                  child: _DownloadedSeriesCard(
                    series: series,
                    onTap: () => _openOfflineSeriesDetail(context, series),
                    onDelete: () => _confirmDeleteSeries(context, ref, series),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openOfflineSeriesDetail(BuildContext context, DownloadedSeries series) {
    context.push(AppPaths.offlineSeriesDetail(series.id), extra: series);
  }

  Future<void> _confirmDeleteSeries(
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
          'Các chương và ảnh bìa đã lưu (${series.formattedSize}) sẽ được xóa khỏi bộ nhớ thiết bị.',
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
      messenger.showSnackBar(
        SnackBar(content: Text('Đã xóa bản tải "${series.title}"')),
      );
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tất cả bản tải?'),
        content: const Text(
          'Toàn bộ các tác phẩm đã tải về máy sẽ bị xóa khỏi bộ nhớ để giải phóng dung lượng. Hành động này không thể hoàn tác.',
        ),
        actions: [
          JoyleeButton(
            label: 'Hủy',
            variant: JoyleeButtonVariant.ghost,
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          JoyleeButton(
            label: 'Xóa tất cả',
            variant: JoyleeButtonVariant.danger,
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(downloadedSeriesViewModelProvider.notifier).deleteAll();
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xóa toàn bộ truyện đã tải')),
      );
    }
  }
}

/// Thanh hiển thị tổng dung lượng đã sử dụng
class _StorageInfoBar extends StatelessWidget {
  const _StorageInfoBar({
    required this.count,
    required this.formattedTotalSize,
    required this.onDeleteAll,
  });

  final int count;
  final String formattedTotalSize;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space3,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(Icons.offline_pin_rounded, size: 20, color: colors.primaryBrand),
          const SizedBox(width: AppDimensions.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count tác phẩm ngoại tuyến',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'Dung lượng: $formattedTotalSize',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDeleteAll,
            child: Text(
              'Xóa tất cả',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ hiển thị một tác phẩm đã tải
class _DownloadedSeriesCard extends StatelessWidget {
  const _DownloadedSeriesCard({
    required this.series,
    required this.onTap,
    required this.onDelete,
  });

  final DownloadedSeries series;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space3),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              child: SizedBox(
                width: 65,
                height: 90,
                child: _buildCoverImage(colors),
              ),
            ),
            const SizedBox(width: AppDimensions.space3),

            // Thông tin truyện
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    series.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryBrand.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${series.downloadedChaptersCount}/${series.totalChapters} chương',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.primaryBrand,
                          ),
                        ),
                      ),
                      Text(
                        series.formattedSize,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Nút xóa
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colors.danger,
                size: 22,
              ),
              tooltip: 'Xóa bản tải',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(AppColors colors) {
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
        errorBuilder: (_, _, _) => _placeholder(colors),
      );
    }
    return _placeholder(colors);
  }

  Widget _placeholder(AppColors colors) {
    return Container(
      color: colors.bgSurfaceSubtle,
      child: Center(
        child: Icon(
          Icons.book_rounded,
          color: colors.textSecondary.withAlpha(100),
          size: 28,
        ),
      ),
    );
  }
}
