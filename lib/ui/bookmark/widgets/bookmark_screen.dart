import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/offline_series.dart';
import '../../../domain/models/series.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../../notifications/widgets/notification_bell_button.dart';
import '../view_models/bookmark_list_view_model.dart';
import '../view_models/offline_library_view_model.dart';
import '../view_models/reading_history_view_model.dart';
import 'library_series_card.dart';
import 'offline_library_screen.dart';

class BookmarkScreen extends ConsumerStatefulWidget {
  const BookmarkScreen({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  ConsumerState<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends ConsumerState<BookmarkScreen>
    with SingleTickerProviderStateMixin {
  ValueListenable<TickerModeData>? _tickerModeNotifier;
  bool _isTabVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh(silent: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    final visible = _tickerModeNotifier?.value.enabled ?? true;
    final becameVisible = visible && !_isTabVisible;
    _isTabVisible = visible;
    if (becameVisible && mounted) unawaited(_refresh(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tủ sách của tôi'),
          actions: const [NotificationBellButton()],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đang đọc'),
              Tab(text: 'Đã lưu'),
              Tab(text: 'Tải xuống'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ReadingTab(), _BookmarksTab(), _DownloadsTab()],
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
    ]);
  }
}

class _ReadingTab extends ConsumerWidget {
  const _ReadingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readingHistoryViewModelProvider);
    final viewModel = ref.read(readingHistoryViewModelProvider.notifier);
    return _StatefulLibraryTab(
      state: state,
      onRefresh: viewModel.refresh,
      errorMessage: 'Không thể tải lịch sử đọc.',
      empty: const JoyleeEmptyState(
        iconData: Icons.menu_book_outlined,
        title: 'Chưa có lịch sử đọc',
        message: 'Bắt đầu đọc một truyện để lưu lại hành trình của bạn.',
      ),
      builder: (history) => _SeriesList(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final entry = history[index];
          return LibrarySeriesCard(
            series: entry.series,
            history: entry,
            onTap: () => context.push(
              AppPaths.seriesDetail(entry.seriesId),
              extra: entry.series,
            ),
          );
        },
      ),
    );
  }
}

class _BookmarksTab extends ConsumerStatefulWidget {
  const _BookmarksTab();

  @override
  ConsumerState<_BookmarksTab> createState() => _BookmarksTabState();
}

class _BookmarksTabState extends ConsumerState<_BookmarksTab> {
  final Set<String> _inFlightIds = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookmarkListViewModelProvider);
    final viewModel = ref.read(bookmarkListViewModelProvider.notifier);
    return _StatefulLibraryTab(
      state: state,
      onRefresh: viewModel.refresh,
      errorMessage: 'Không thể tải truyện đã lưu.',
      empty: const JoyleeEmptyState(
        iconData: Icons.bookmark_border_rounded,
        title: 'Tủ sách đang trống',
        message: 'Lưu truyện yêu thích để tìm và đọc lại dễ dàng.',
      ),
      builder: (bookmarks) => _SeriesList(
        itemCount: bookmarks.length,
        itemBuilder: (context, index) {
          final series = bookmarks[index];
          return LibrarySeriesCard(
            series: series,
            onRemoveBookmark: () => _removeBookmark(series),
            isBookmarkActionLoading: _inFlightIds.contains(series.id),
            onTap: () =>
                context.push(AppPaths.seriesDetail(series.id), extra: series),
          );
        },
      ),
    );
  }

  Future<void> _removeBookmark(Series series) async {
    if (!_inFlightIds.add(series.id)) return;
    setState(() {});
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

class _DownloadsTab extends ConsumerWidget {
  const _DownloadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(offlineLibraryViewModelProvider);
    final viewModel = ref.read(offlineLibraryViewModelProvider.notifier);
    return _StatefulLibraryTab(
      state: state,
      onRefresh: viewModel.refresh,
      errorMessage: 'Không thể tải truyện đã tải xuống.',
      empty: const JoyleeEmptyState(
        iconData: Icons.download_for_offline_outlined,
        title: 'Chưa có truyện tải xuống',
        message: 'Tải từng chapter để truyện xuất hiện trong thư viện này.',
      ),
      builder: (series) => _SeriesList(
        itemCount: series.length,
        itemBuilder: (context, index) {
          final item = series[index];
          return OfflineSeriesCard(
            series: item,
            onTap: () => context.push(AppPaths.offlineSeries(item.id)),
            onDelete: () => _confirmDelete(context, viewModel, item),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OfflineLibraryViewModel viewModel,
    OfflineSeries series,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa truyện đã tải?'),
        content: Text('Xóa toàn bộ chapter offline của "${series.title}"?'),
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
    if (confirmed == true) await viewModel.deleteSeries(series.id);
  }
}

class _StatefulLibraryTab<T> extends StatelessWidget {
  const _StatefulLibraryTab({
    required this.state,
    required this.onRefresh,
    required this.errorMessage,
    required this.empty,
    required this.builder,
  });

  final AsyncValue<T> state;
  final Future<void> Function() onRefresh;
  final String errorMessage;
  final Widget empty;
  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => JoyleeErrorView(
        message: error is AppException ? error.message : errorMessage,
        onRetry: onRefresh,
      ),
      data: (value) {
        if (value is Iterable && value.isEmpty) return empty;
        return RefreshIndicator(onRefresh: onRefresh, child: builder(value));
      },
    );
  }
}

/// Danh sách series dùng chung cho ba tab Tủ sách.
class _SeriesList extends StatelessWidget {
  const _SeriesList({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space2,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.space4),
      itemBuilder: itemBuilder,
    );
  }
}
