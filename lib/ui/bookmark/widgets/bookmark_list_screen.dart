import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/series.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../../series/widgets/series_card.dart';
import '../view_models/bookmark_list_view_model.dart';

class BookmarkListScreen extends ConsumerStatefulWidget {
  const BookmarkListScreen({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  ConsumerState<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends ConsumerState<BookmarkListScreen> {
  final Set<String> _inFlightIds = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarkListViewModelProvider);
    final viewModel = ref.read(bookmarkListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Truyện đã lưu')),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => JoyleeErrorView(
            message: error is AppException
                ? error.message
                : 'Đã có lỗi xảy ra.',
            onRetry: viewModel.refresh,
          ),
          data: (bookmarks) => bookmarks.isEmpty
              ? _buildEmptyState(viewModel)
              : RefreshIndicator(
                  onRefresh: viewModel.refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimensions.space4),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final series = bookmarks[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SeriesCard(
                            series: series,
                            isBookmarkActionLoading: _inFlightIds.contains(
                              series.id,
                            ),
                            bookmarkActionIcon: Icons.delete_outline_rounded,
                            bookmarkActionTooltip: 'Xóa khỏi tủ sách',
                            onTap: () => _openSeries(context, series),
                            onBookmarkTap: () => _removeBookmark(series),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BookmarkListViewModel viewModel) => RefreshIndicator(
    onRefresh: viewModel.refresh,
    child: LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: JoyleeEmptyState(
              iconData: Icons.bookmark_border_rounded,
              title: 'Tủ sách đang trống',
              message:
                  'Lưu những tác phẩm yêu thích để tìm và đọc lại dễ dàng.',
              actionLabel: 'Khám phá truyện',
              onAction: widget.onExplore ?? () => context.go(AppPaths.series),
            ),
          ),
        ],
      ),
    ),
  );

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
