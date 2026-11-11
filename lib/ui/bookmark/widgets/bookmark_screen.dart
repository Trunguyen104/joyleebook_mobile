import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/reading_history.dart';
import '../../../domain/models/series.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../../download/view_models/downloaded_series_view_model.dart';
import '../../download/widgets/downloaded_series_screen.dart';
import '../../notifications/widgets/notification_bell_button.dart';
import '../../series/widgets/series_card.dart';
import '../view_models/bookmark_list_view_model.dart';
import '../view_models/reading_history_view_model.dart';
import 'reading_history_screen.dart';

/// MÀN HÌNH TỦ SÁCH CÁ NHÂN (BookmarkScreen)
/// Gồm 3 tab đặt ngay dưới AppBar:
/// 1. Đang đọc (Lịch sử đọc gần đây)
/// 2. Đã lưu (Tủ sách yêu thích)
/// 3. Đã tải (Truyện đọc ngoại tuyến từ SQLite)
class BookmarkScreen extends ConsumerStatefulWidget {
  const BookmarkScreen({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  ConsumerState<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends ConsumerState<BookmarkScreen> {
  final Set<String> _inFlightIds = {};
  ValueListenable<TickerModeData>? _tickerModeNotifier;
  bool _isTabVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bookmarks = ref.read(bookmarkListViewModelProvider);
        if (!bookmarks.isLoading &&
            (bookmarks.value == null || bookmarks.hasError)) {
          ref.read(bookmarkListViewModelProvider.notifier).refresh();
        }
        final history = ref.read(readingHistoryViewModelProvider);
        if (!history.isLoading && (history.value == null || history.hasError)) {
          ref.read(readingHistoryViewModelProvider.notifier).refresh();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tab tủ sách nằm trong IndexedStack nên không bị hủy khi chuyển tab.
    // Lắng nghe TickerMode để tải lại dữ liệu mỗi khi tab được mở lại.
    final notifier = TickerMode.getValuesNotifier(context);
    if (!identical(notifier, _tickerModeNotifier)) {
      _tickerModeNotifier?.removeListener(_handleTickerModeChanged);
      _tickerModeNotifier = notifier;
      notifier.addListener(_handleTickerModeChanged);
      _isTabVisible = notifier.value.enabled;
    }
  }

  @override
  void dispose() {
    _tickerModeNotifier?.removeListener(_handleTickerModeChanged);
    super.dispose();
  }

  void _handleTickerModeChanged() {
    final isVisibleNow = _tickerModeNotifier?.value.enabled ?? true;
    final becameVisible = isVisibleNow && !_isTabVisible;
    _isTabVisible = isVisibleNow;
    if (!becameVisible || !mounted) return;
    unawaited(_refresh(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final historyState = ref.watch(readingHistoryViewModelProvider);
    final bookmarksState = ref.watch(bookmarkListViewModelProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(
          title: const Text('Tủ sách của tôi'),
          actions: const [NotificationBellButton()],
          bottom: TabBar(
            indicatorColor: colors.primaryBrand,
            labelColor: colors.primaryBrand,
            unselectedLabelColor: colors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Đang đọc'),
              Tab(text: 'Đã lưu'),
              Tab(text: 'Đã tải'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryTab(context, historyState),
            _buildBookmarksTab(context, bookmarksState),
            DownloadedSeriesListView(onExplore: _explore),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh({bool silent = false}) async {
    await Future.wait([
      ref
          .read(readingHistoryViewModelProvider.notifier)
          .refresh(showLoading: !silent),
      ref
          .read(bookmarkListViewModelProvider.notifier)
          .refresh(showLoading: !silent),
      ref
          .read(downloadedSeriesViewModelProvider.notifier)
          .refresh(showLoading: !silent),
    ]);
  }

  Widget _buildHistoryTab(
    BuildContext context,
    AsyncValue<List<ReadingHistory>> state,
  ) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(readingHistoryViewModelProvider.notifier).refresh(),
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 64),
            JoyleeErrorView(
              message: error is AppException
                  ? error.message
                  : 'Đã có lỗi xảy ra.',
              onRetry: () =>
                  ref.read(readingHistoryViewModelProvider.notifier).refresh(),
            ),
          ],
        ),
        data: (history) {
          if (history.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 48),
                JoyleeEmptyState(
                  iconData: Icons.menu_book_outlined,
                  title: 'Chưa có lịch sử đọc',
                  message: 'Những truyện bạn đã đọc sẽ xuất hiện ở đây.',
                  actionLabel: 'Khám phá truyện',
                  onAction: _explore,
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.space4),
            itemCount: history.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDimensions.space2),
            itemBuilder: (context, index) {
              final entry = history[index];
              return HistoryListTile(
                key: ValueKey('history-${entry.seriesId}'),
                entry: entry,
                onTap: () => _openSeries(context, entry.series),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookmarksTab(
    BuildContext context,
    AsyncValue<List<Series>> state,
  ) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(bookmarkListViewModelProvider.notifier).refresh(),
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 64),
            JoyleeErrorView(
              message: error is AppException
                  ? error.message
                  : 'Đã có lỗi xảy ra.',
              onRetry: () =>
                  ref.read(bookmarkListViewModelProvider.notifier).refresh(),
            ),
          ],
        ),
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 48),
                JoyleeEmptyState(
                  iconData: Icons.bookmark_border_rounded,
                  title: 'Tủ sách đang trống',
                  message: 'Lưu truyện yêu thích để tìm và đọc lại dễ dàng.',
                  actionLabel: 'Khám phá truyện',
                  onAction: _explore,
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.space4),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final series = bookmarks[index];
              return SeriesCard(
                key: ValueKey('bookmark-${series.id}'),
                series: series,
                isBookmarkActionLoading: _inFlightIds.contains(series.id),
                bookmarkActionIcon: Icons.bookmark_remove_outlined,
                bookmarkActionTooltip: 'Bỏ lưu',
                onTap: () => _openSeries(context, series),
                onBookmarkTap: () => _removeBookmark(series),
              );
            },
          );
        },
      ),
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
