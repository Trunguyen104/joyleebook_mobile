import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/series.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../../series/widgets/series_card.dart';
import '../../series/widgets/series_detail_screen.dart';
import '../view_models/bookmark_list_view_model.dart';

class BookmarkScreen extends ConsumerStatefulWidget {
  const BookmarkScreen({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  ConsumerState<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends ConsumerState<BookmarkScreen> {
  final Set<String> _inFlightIds = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarkListViewModelProvider);
    final viewModel = ref.read(bookmarkListViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tủ sách của tôi'),
        actions: [
          IconButton(
            tooltip: 'Làm mới tủ sách',
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
          data: (bookmarks) => bookmarks.isEmpty
              ? _buildEmptyState(context, viewModel)
              : RefreshIndicator(
                  onRefresh: viewModel.refresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimensions.space4),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final series = bookmarks[index];
                      final isLoading = _inFlightIds.contains(series.id);
                      return SeriesCard(
                        series: series,
                        isBookmarkActionLoading: isLoading,
                        onTap: () => _openSeries(context, series),
                        onBookmarkTap: () => _removeBookmark(series),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    BookmarkListViewModel viewModel,
  ) {
    return RefreshIndicator(
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
                onAction:
                    widget.onExplore ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hãy mở tab Kho Truyện để khám phá.'),
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSeries(BuildContext context, Series series) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeriesDetailScreen(initialSeries: series),
      ),
    );
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
