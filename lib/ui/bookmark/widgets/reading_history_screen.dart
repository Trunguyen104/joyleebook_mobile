import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/reading_history.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/reading_history_view_model.dart';
import 'reading_progress_view.dart';

class ReadingHistoryScreen extends ConsumerWidget {
  const ReadingHistoryScreen({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readingHistoryViewModelProvider);
    final viewModel = ref.read(readingHistoryViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đọc'),
        actions: [
          IconButton(
            tooltip: 'Làm mới lịch sử đọc',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: viewModel.refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => JoyleeErrorView(
            message: error is AppException
                ? error.message
                : 'Đã có lỗi xảy ra.',
            onRetry: viewModel.refresh,
          ),
          data: (history) => history.isEmpty
              ? _buildEmptyState(context, viewModel)
              : RefreshIndicator(
                  onRefresh: viewModel.refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimensions.space4),
                    itemCount: history.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimensions.space2),
                    itemBuilder: (context, index) => _HistoryListTile(
                      entry: history[index],
                      onTap: () => context.push(
                        AppPaths.seriesDetail(history[index].seriesId),
                        extra: history[index].series,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ReadingHistoryViewModel viewModel,
  ) => RefreshIndicator(
    onRefresh: viewModel.refresh,
    child: LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: JoyleeEmptyState(
              iconData: Icons.menu_book_outlined,
              title: 'Chưa có lịch sử đọc',
              message: 'Bắt đầu đọc một truyện để lưu lại hành trình của bạn.',
              actionLabel: 'Khám phá truyện',
              onAction: onExplore ?? () => context.go(AppPaths.series),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HistoryListTile extends StatelessWidget {
  const _HistoryListTile({required this.entry, required this.onTap});

  final ReadingHistory entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chapter = entry.chapterTitle?.trim().isNotEmpty == true
        ? entry.chapterTitle!.trim()
        : entry.chapterNumber != null
        ? 'Chương ${entry.chapterNumber}'
        : 'Chưa có thông tin chương';

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space3),
          child: Row(
            children: [
              _buildCover(colors),
              const SizedBox(width: AppDimensions.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.series.title.trim().isEmpty
                          ? 'Chưa có tiêu đề'
                          : entry.series.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space1),
                    Text(
                      'Đọc gần nhất: $chapter',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (entry.lastReadAt != null) ...[
                      const SizedBox(height: AppDimensions.space1),
                      Text(
                        _formatDate(entry.lastReadAt!),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimensions.space2),
                    ReadingProgressView(
                      seriesId: entry.seriesId,
                      progress: entry.progress,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space2),
              Icon(Icons.chevron_right_rounded, color: colors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(AppColors colors) => Container(
    width: 72,
    height: 100,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: colors.bgSurfaceSubtle,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
    ),
    child: entry.series.coverImageUrl.isEmpty
        ? Icon(Icons.auto_stories_rounded, color: colors.textDisabled)
        : Image.network(
            entry.series.coverImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Icon(Icons.auto_stories_rounded, color: colors.textDisabled),
          ),
  );

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
