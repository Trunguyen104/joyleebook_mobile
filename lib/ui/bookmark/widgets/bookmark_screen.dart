import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/reading_history.dart';
import '../../../domain/models/series.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/bookmark_list_view_model.dart';
import '../view_models/reading_history_view_model.dart';
import 'library_series_card.dart';

class BookmarkScreen extends ConsumerStatefulWidget {
  const BookmarkScreen({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  ConsumerState<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends ConsumerState<BookmarkScreen> {
  final Set<String> _inFlightIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bookmarks = ref.read(bookmarkListViewModelProvider);
        if (bookmarks.value == null || bookmarks.hasError) {
          ref.read(bookmarkListViewModelProvider.notifier).refresh();
        }
        final history = ref.read(readingHistoryViewModelProvider);
        if (history.value == null || history.hasError) {
          ref.read(readingHistoryViewModelProvider.notifier).refresh();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(readingHistoryViewModelProvider);
    final bookmarksState = ref.watch(bookmarkListViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tủ sách của tôi')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            top: AppDimensions.space2,
            bottom: AppDimensions.space6,
          ),
          children: [
            _SectionHeader(
              title: 'Đang đọc gần đây',
              onViewAll: () => context.push(AppPaths.readingHistory),
            ),
            _buildHistorySection(context, historyState),
            const SizedBox(height: AppDimensions.space6),
            _SectionHeader(
              title: 'Truyện đã lưu',
              onViewAll: () => context.push(AppPaths.bookmarkList),
            ),
            _buildBookmarksSection(context, bookmarksState),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(readingHistoryViewModelProvider.notifier).refresh(),
      ref.read(bookmarkListViewModelProvider.notifier).refresh(),
    ]);
  }

  Widget _buildHistorySection(
    BuildContext context,
    AsyncValue<List<ReadingHistory>> state,
  ) {
    return state.when(
      loading: () => const _SectionLoading(),
      error: (error, _) => _SectionError(
        message: error is AppException ? error.message : 'Đã có lỗi xảy ra.',
        onRetry: () =>
            ref.read(readingHistoryViewModelProvider.notifier).refresh(),
      ),
      data: (history) {
        if (history.isEmpty) {
          return _SectionEmpty(
            icon: Icons.menu_book_outlined,
            title: 'Chưa có lịch sử đọc',
            message: 'Những truyện bạn đã đọc sẽ xuất hiện ở đây.',
            actionLabel: 'Khám phá truyện',
            onAction: _explore,
          );
        }
        final displayItems = history.take(4).toList();
        return _seriesGrid(displayItems.length, (index) {
          final entry = displayItems[index];
          return LibrarySeriesCard(
            key: ValueKey('history-${entry.seriesId}'),
            series: entry.series,
            history: entry,
            onTap: () => _openSeries(context, entry.series),
          );
        });
      },
    );
  }

  Widget _buildBookmarksSection(
    BuildContext context,
    AsyncValue<List<Series>> state,
  ) {
    return state.when(
      loading: () => const _SectionLoading(),
      error: (error, _) => _SectionError(
        message: error is AppException ? error.message : 'Đã có lỗi xảy ra.',
        onRetry: () =>
            ref.read(bookmarkListViewModelProvider.notifier).refresh(),
      ),
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return _SectionEmpty(
            icon: Icons.bookmark_border_rounded,
            title: 'Tủ sách đang trống',
            message: 'Lưu truyện yêu thích để tìm và đọc lại dễ dàng.',
            actionLabel: 'Khám phá truyện',
            onAction: _explore,
          );
        }
        final displayItems = bookmarks.take(4).toList();
        return _seriesGrid(displayItems.length, (index) {
          final series = displayItems[index];
          return LibrarySeriesCard(
            key: ValueKey('bookmark-${series.id}'),
            series: series,
            onTap: () => _openSeries(context, series),
            onRemoveBookmark: () => _removeBookmark(series),
            isBookmarkActionLoading: _inFlightIds.contains(series.id),
          );
        });
      },
    );
  }

  Widget _seriesGrid(int itemCount, Widget Function(int index) itemBuilder) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - AppDimensions.space4 * 2;
        final crossAxisCount =
            ((availableWidth + AppDimensions.space3) /
                    (145 + AppDimensions.space3))
                .floor()
                .clamp(1, 4);
        final cardWidth =
            (availableWidth - AppDimensions.space3 * (crossAxisCount - 1)) /
            crossAxisCount;
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppDimensions.space3,
            mainAxisSpacing: AppDimensions.space3,
            childAspectRatio:
                cardWidth / (cardWidth < 200 ? 225 : cardWidth * 0.9),
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) => itemBuilder(index),
        );
      },
    );
  }

  void _explore() {
    if (widget.onExplore != null) {
      widget.onExplore!();
    } else {
      context.go(AppPaths.series);
    }
  }

  void _openSeries(BuildContext context, Series series) {
    context.push(AppPaths.seriesDetail(series.id), extra: series);
  }

  Future<void> _removeBookmark(Series series) async {
    if (_inFlightIds.contains(series.id)) return;
    setState(() => _inFlightIds.add(series.id));

    final success = await ref
        .read(bookmarkListViewModelProvider.notifier)
        .removeBookmark(series.id);

    if (!mounted) return;
    setState(() => _inFlightIds.remove(series.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã bỏ lưu "${series.title}" khỏi tủ sách.'
              : 'Không thể cập nhật tủ sách. Đã hoàn tác trạng thái.',
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppDimensions.space4,
      AppDimensions.space3,
      AppDimensions.space2,
      AppDimensions.space2,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(onPressed: onViewAll, child: const Text('Xem tất cả')),
      ],
    ),
  );
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 180,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 260,
    child: JoyleeErrorView(message: message, onRetry: onRetry),
  );
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppDimensions.space4,
      AppDimensions.space3,
      AppDimensions.space4,
      AppDimensions.space4,
    ),
    child: Row(
      children: [
        Icon(icon, size: 36, color: Theme.of(context).disabledColor),
        const SizedBox(width: AppDimensions.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppDimensions.space1),
              Text(message, style: Theme.of(context).textTheme.bodySmall),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ],
    ),
  );
}
