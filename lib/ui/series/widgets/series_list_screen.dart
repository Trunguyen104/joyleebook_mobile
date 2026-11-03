import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:joyleebook_mobile/ui/core/themes/theme_provider.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/series.dart';
import '../../../routing/app_paths.dart';
import '../../bookmark/view_models/bookmark_status_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/series_list_view_model.dart';
import 'genre_filter_bar.dart';
import 'series_card.dart';

/// MÀN HÌNH KHÁM PHÁ & TRA CỨU TRUYỆN (SeriesListScreen / Research & Genres)
/// Bước 5 trong kiến trúc Compass App:
/// Dành riêng cho Actor Reader (Độc giả).
///
/// BẢO ĐẢM CÁC TIÊU CHUẨN KỸ THUẬT:
/// 1. Bộ 4 Trạng thái (4 States): Loading -> Error -> Empty -> Data.
/// 2. Debounce 400ms: Ô tìm kiếm tra cứu chống spam request.
/// 3. Lọc đa tiêu chí: Lọc theo Thể loại (Genre) và Trạng thái phát hành (Status).
/// 4. Optimistic UI: Bookmark tức thì, rollback khi mất mạng/lỗi server.
/// 5. Warm Editorial Theme: Material 3, Light & Dark mode, không RenderFlex overflow.
class SeriesListScreen extends ConsumerStatefulWidget {
  const SeriesListScreen({super.key});

  @override
  ConsumerState<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends ConsumerState<SeriesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _bookmarkRequestsInFlight = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final seriesState = ref.watch(seriesListViewModelProvider);
    final bookmarkStatuses = ref.watch(bookmarkStatusViewModelProvider);
    final seriesVm = ref.watch(seriesListViewModelProvider.notifier);
    final isFiltered = seriesVm.isFiltered;

    // Đồng bộ nếu bộ lọc từ khóa bị xóa từ ViewModel
    if (seriesVm.currentQuery.isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: Text(
          'Kho Truyện JoyleeBook',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Đổi giao diện Sáng / Tối',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới danh sách',
            onPressed: () =>
                ref.read(seriesListViewModelProvider.notifier).refresh(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(118),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space4,
                  vertical: AppDimensions.space1,
                ),
                child: _buildSearchBar(colors),
              ),
              const GenreFilterBar(),
              const SizedBox(height: AppDimensions.space2),
            ],
          ),
        ),
      ),

      // THỰC HIỆN BỘ 4 TRẠNG THÁI BẰNG HÀM .when() CỦA RIVERPOD
      body: seriesState.when(
        // TRẠNG THÁI 1: LOADING
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colors.primaryBrand),
              ),
              const SizedBox(height: AppDimensions.space3),
              Text(
                'Đang tải kho truyện...',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),

        // TRẠNG THÁI 2: ERROR
        error: (err, stack) => JoyleeErrorView(
          message: err is AppException ? err.message : 'Đã có lỗi xảy ra.',
          onRetry: () =>
              ref.read(seriesListViewModelProvider.notifier).refresh(),
        ),

        // TRẠNG THÁI 3 & 4: CÓ DỮ LIỆU HOẶC DANH SÁCH RỖNG
        data: (seriesList) {
          // A. Danh sách rỗng -> Empty State
          if (seriesList.isEmpty) {
            return JoyleeEmptyState(
              title: 'Không tìm thấy truyện nào',
              message: isFiltered
                  ? (_searchController.text.isNotEmpty
                      ? 'Không có kết quả nào khớp với từ khóa "${_searchController.text}".'
                      : 'Không có tác phẩm nào phù hợp với bộ lọc đã chọn.')
                  : 'Hiện tại chưa có tác phẩm nào được xuất bản trên hệ thống.',
              actionLabel: isFiltered ? 'Xóa bộ lọc' : 'Tải lại toàn bộ',
              onAction: () {
                _searchController.clear();
                ref.read(seriesListViewModelProvider.notifier).clearFilters();
              },
            );
          }

          // B. Có dữ liệu -> Hiển thị danh sách kèm banner bộ lọc nếu có
          final showBanner = isFiltered;
          final totalItems = seriesList.length + (showBanner ? 1 : 0);

          return RefreshIndicator(
            color: colors.primaryBrand,
            backgroundColor: colors.bgSurface,
            onRefresh: () =>
                ref.read(seriesListViewModelProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.space4),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                if (showBanner && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.space3),
                    child: _buildActiveFiltersBanner(
                      colors,
                      seriesVm,
                      seriesList.length,
                    ),
                  );
                }

                final storedItem =
                    seriesList[showBanner ? index - 1 : index];
                final item = storedItem.copyWith(
                  isBookmarked:
                      bookmarkStatuses[storedItem.id] ??
                      storedItem.isBookmarked,
                );
                final isBookmarkActionLoading =
                    _bookmarkRequestsInFlight.contains(item.id);

                return SeriesCard(
                  series: item,
                  isBookmarkActionLoading: isBookmarkActionLoading,
                  onTap: () {
                    context.push(AppPaths.seriesDetail(item.id), extra: item);
                  },
                  onBookmarkTap: () => _toggleBookmark(item, colors),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Banner thông báo bộ lọc đang active
  Widget _buildActiveFiltersBanner(
    AppColors colors,
    SeriesListViewModel vm,
    int count,
  ) {
    final List<String> activeFilterLabels = [];
    if (vm.currentQuery.isNotEmpty) {
      activeFilterLabels.add('Từ khóa: "${vm.currentQuery}"');
    }
    if (vm.selectedGenre != null) {
      activeFilterLabels.add('Thể loại: ${vm.selectedGenre}');
    }
    if (vm.selectedStatus != null) {
      activeFilterLabels.add('Trạng thái: ${vm.selectedStatus!.label}');
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space3,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: colors.primaryBrand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: colors.primaryBrand.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, size: 16, color: colors.primaryBrand),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tìm thấy $count tác phẩm phù hợp',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryBrand,
                  ),
                ),
                if (activeFilterLabels.isNotEmpty)
                  Text(
                    activeFilterLabels.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              _searchController.clear();
              ref.read(seriesListViewModelProvider.notifier).clearFilters();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(48, 36),
            ),
            child: Text(
              'Xóa bộ lọc',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBookmark(Series item, AppColors colors) async {
    if (_bookmarkRequestsInFlight.contains(item.id)) return;
    setState(() => _bookmarkRequestsInFlight.add(item.id));

    late final bool success;
    try {
      success = await ref
          .read(seriesListViewModelProvider.notifier)
          .toggleBookmark(item.id);
    } finally {
      if (mounted) {
        setState(() => _bookmarkRequestsInFlight.remove(item.id));
      }
    }

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Không thể cập nhật tủ sách. Đã hoàn tác trạng thái.',
          ),
          backgroundColor: colors.danger,
        ),
      );
    }
  }

  /// Khung tìm kiếm có hỗ trợ nút Xóa nhanh và debounce 400ms
  Widget _buildSearchBar(AppColors colors) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        ref.read(seriesListViewModelProvider.notifier).search(value);
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Tìm kiếm tựa truyện, tác giả...',
        hintStyle: TextStyle(color: colors.textDisabled, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: colors.textSecondary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  ref.read(seriesListViewModelProvider.notifier).search('');
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: colors.bgSurface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space4,
          vertical: AppDimensions.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
      ),
    );
  }
}
