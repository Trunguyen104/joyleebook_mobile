import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/offline_chapter.dart';
import '../../../domain/models/offline_series.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/offline_library_view_model.dart';

class OfflineLibraryScreen extends ConsumerWidget {
  const OfflineLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offlineLibraryViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tải xuống')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => JoyleeErrorView(
          message: 'Không thể tải danh sách truyện offline.',
          onRetry: () =>
              ref.read(offlineLibraryViewModelProvider.notifier).refresh(),
        ),
        data: (series) {
          if (series.isEmpty) {
            return const JoyleeEmptyState(
              iconData: Icons.download_for_offline_outlined,
              title: 'Chưa có truyện tải xuống',
              message:
                  'Tải từng chapter để truyện xuất hiện trong thư viện này.',
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(offlineLibraryViewModelProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.space4),
              itemCount: series.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDimensions.space3),
              itemBuilder: (context, index) {
                final item = series[index];
                return OfflineSeriesCard(
                  series: item,
                  onTap: () => context.push(AppPaths.offlineSeries(item.id)),
                  onDelete: () => _confirmDeleteSeries(context, ref, item),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteSeries(
    BuildContext context,
    WidgetRef ref,
    OfflineSeries series,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa truyện đã tải?'),
        content: Text(
          'Xóa ${series.chapters.length} chapter offline của "${series.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(offlineLibraryViewModelProvider.notifier)
          .deleteSeries(series.id);
    }
  }
}

class OfflineSeriesChaptersScreen extends ConsumerWidget {
  const OfflineSeriesChaptersScreen({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offlineLibraryViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chapter đã tải')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => JoyleeErrorView(
          message: 'Không thể tải danh sách chapter offline.',
          onRetry: () =>
              ref.read(offlineLibraryViewModelProvider.notifier).refresh(),
        ),
        data: (seriesList) {
          OfflineSeries? series;
          for (final item in seriesList) {
            if (item.id == seriesId) {
              series = item;
              break;
            }
          }
          if (series == null || series.chapters.isEmpty) {
            return const JoyleeEmptyState(
              iconData: Icons.download_for_offline_outlined,
              title: 'Không còn chapter offline',
              message: 'Các chapter của truyện này đã được xóa khỏi thiết bị.',
            );
          }
          final selected = series;
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(offlineLibraryViewModelProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: selected.chapters.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chapter = selected.chapters[index];
                return _OfflineChapterTile(
                  chapter: chapter,
                  seriesTitle: selected.title,
                  onOpen: () => context.push(
                    AppPaths.chapterReader(selected.id, chapter.id),
                    extra: selected.title,
                  ),
                  onDelete: () => ref
                      .read(offlineLibraryViewModelProvider.notifier)
                      .deleteChapter(chapter),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class OfflineSeriesCard extends StatelessWidget {
  const OfflineSeriesCard({
    super.key,
    required this.series,
    required this.onTap,
    required this.onDelete,
  });

  final OfflineSeries series;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
            Container(
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
              child: _Cover(imageUrl: series.coverImageUrl),
            ),
            const SizedBox(width: AppDimensions.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title.isEmpty ? 'Chưa có tiêu đề' : series.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space1),
                  Text(
                    '${series.chapters.length} chương đã tải xuống',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.space1),
            SizedBox(
              width: AppDimensions.minTouchTarget,
              height: AppDimensions.minTouchTarget,
              child: IconButton(
                tooltip: 'Xóa truyện offline',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, color: colors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineChapterTile extends StatelessWidget {
  const _OfflineChapterTile({
    required this.chapter,
    required this.seriesTitle,
    required this.onOpen,
    required this.onDelete,
  });

  final OfflineChapter chapter;
  final String seriesTitle;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.offline_pin_rounded),
      title: Text(
        'Chương ${chapter.sortOrder}: ${chapter.title}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(seriesTitle),
      onTap: onOpen,
      trailing: IconButton(
        tooltip: 'Xóa chapter offline',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.auto_stories_rounded),
    );
    if (imageUrl.isEmpty) return placeholder;
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
