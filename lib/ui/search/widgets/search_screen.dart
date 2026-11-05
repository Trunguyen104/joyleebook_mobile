import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/genre.dart';
import '../../../domain/models/series.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../../series/view_models/genre_list_view_model.dart';
import '../view_models/search_view_model.dart';
import 'search_genre_bottom_sheet.dart';

/// MÀN HÌNH KHÁM PHÁ & TÌM KIẾM (SearchScreen)
/// Thiết kế giao diện xếp hạng theo chuẩn Wattpad (Image 2):
/// 1. Ô tìm kiếm trên đầu: "Tìm truyện hoặc người"
/// 2. Thanh danh mục thể loại cuộn ngang ĐƯỢC SORT THEO BẢNG CHỮ CÁI (A-Z / ABC).
/// 3. Dòng thông tin số lượng: "{count} Truyện" + Nút [Lọc]
/// 4. Danh sách truyện xếp hạng dạng cột (Rank 1, 2, 3...)
///
/// DỮ LIỆU THẬT 100%:
/// - Tuyệt đối không tạo số view mẫu: Nếu API không trả viewCount thì ẩn icon mắt và lượt view.
/// - Chỉ hiển thị số chương thật (totalChapters) và điểm đánh giá thật (averageRating).
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialGenre;

  const SearchScreen({super.key, this.initialGenre});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGenreExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialGenre != null && widget.initialGenre!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(searchViewModelProvider.notifier)
            .filterByGenre(widget.initialGenre);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final seriesState = ref.watch(searchViewModelProvider);
    final searchVm = ref.watch(searchViewModelProvider.notifier);
    final genresState = ref.watch(genreListViewModelProvider);
    final selectedGenre = searchVm.selectedGenre;

    // Đồng bộ nếu query bị xóa từ ViewModel
    if (searchVm.currentQuery.isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        titleSpacing: AppDimensions.space3,
        title: _buildSearchBar(colors),
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
            tooltip: 'Làm mới',
            onPressed: () =>
                ref.read(searchViewModelProvider.notifier).refresh(),
          ),
          const SizedBox(width: AppDimensions.space1),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _buildGenreTabBar(genresState, selectedGenre, colors),
        ),
      ),

      // THỰC HIỆN BỘ 4 TRẠNG THÁI BẰNG HÀM .when() CỦA RIVERPOD VÀ LỚP PHỦ MỞ RỘNG
      body: Stack(
        children: [
          seriesState.when(
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
                    'Đang tìm kiếm tác phẩm...',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),

            // TRẠNG THÁI 2: ERROR
            error: (err, stack) => JoyleeErrorView(
              message: err is AppException ? err.message : 'Đã có lỗi xảy ra khi tra cứu.',
              onRetry: () =>
                  ref.read(searchViewModelProvider.notifier).refresh(),
            ),

            // TRẠNG THÁI 3 & 4: CÓ DỮ LIỆU HOẶC DANH SÁCH RỖNG
            data: (seriesList) {
              // A. Danh sách rỗng -> Empty State
              if (seriesList.isEmpty) {
                return JoyleeEmptyState(
                  title: 'Không tìm thấy tác phẩm nào',
                  message: searchVm.isFiltered
                      ? (_searchController.text.isNotEmpty
                          ? 'Không có kết quả nào khớp với từ khóa "${_searchController.text}".'
                          : 'Không có tác phẩm nào phù hợp với bộ lọc đã chọn.')
                      : 'Hiện tại chưa có tác phẩm nào được xuất bản trên hệ thống.',
                  actionLabel: searchVm.isFiltered ? 'Xóa bộ lọc' : 'Tải lại toàn bộ',
                  onAction: () {
                    _searchController.clear();
                    ref.read(searchViewModelProvider.notifier).clearFilters();
                  },
                );
              }

              // B. Có dữ liệu -> Hiển thị danh sách xếp hạng theo chuẩn Wattpad (Image 2)
              return RefreshIndicator(
                color: colors.primaryBrand,
                backgroundColor: colors.bgSurface,
                onRefresh: () =>
                    ref.read(searchViewModelProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space4,
                    vertical: AppDimensions.space2,
                  ),
                  children: [
                    // Dòng thống kê số lượng + Nút [Lọc]
                    _buildResultsHeader(seriesList.length, colors),

                    const SizedBox(height: AppDimensions.space3),

                    // Danh sách truyện xếp hạng (1, 2, 3...)
                    ...List.generate(seriesList.length, (index) {
                      final series = seriesList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppDimensions.space4),
                        child: _buildRankedBookTile(
                          rank: index + 1,
                          series: series,
                          colors: colors,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          // LỚP PHỦ MỜ (DIMMED BACKDROP) KHI MỞ RỘNG THỂ LOẠI
          if (_isGenreExpanded) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _isGenreExpanded = false),
                child: Container(
                  color: colors.textPrimary.withValues(alpha: 0.45),
                ),
              ),
            ),

            // KHUNG MỞ RỘNG THỂ LOẠI DẠNG DROPDOWN OVERLAY THEO CHUẨN WATTPAD (Image 3)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: genresState.maybeWhen(
                data: (genres) {
                  final sortedGenres = List<Genre>.from(genres)
                    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                  return _buildExpandedGenrePanel(
                    sortedGenres: sortedGenres,
                    selectedGenre: selectedGenre,
                    colors: colors,
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 1. Ô tìm kiếm chuẩn Wattpad: "Tìm truyện hoặc người"
  Widget _buildSearchBar(AppColors colors) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        ref.read(searchViewModelProvider.notifier).search(value);
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Tìm truyện hoặc người',
        hintStyle: TextStyle(
          color: colors.textSecondary.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        prefixIcon: Icon(Icons.search, color: colors.textSecondary, size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  ref.read(searchViewModelProvider.notifier).search('', immediate: true);
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: colors.bgSurface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space3,
          vertical: AppDimensions.space2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: colors.primaryBrand, width: 1.5),
        ),
      ),
    );
  }

  /// 2. Thanh thể loại dạng Tab ĐƯỢC SORT THEO BẢNG CHỮ CÁI (A-Z / ABC)
  Widget _buildGenreTabBar(
    AsyncValue<List<Genre>> genresState,
    String? selectedGenre,
    AppColors colors,
  ) {
    return genresState.when(
      loading: () => const SizedBox(height: 44),
      error: (_, _) => const SizedBox(height: 44),
      data: (genres) {
        // SẮP XẾP THỂ LOẠI THEO THỨ TỰ BẢNG CHỮ CÁI (A-Z / ABC)
        final sortedGenres = List<Genre>.from(genres)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: colors.bgCanvas,
            border: Border(
              bottom: BorderSide(color: colors.borderDefault, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
                  children: [
                    // Tab "Tất cả" luôn đứng đầu
                    _buildGenreTabItem(
                      label: 'Tất cả',
                      isSelected: selectedGenre == null,
                      colors: colors,
                      onTap: () {
                        if (_isGenreExpanded) setState(() => _isGenreExpanded = false);
                        ref
                            .read(searchViewModelProvider.notifier)
                            .filterByGenre(null);
                      },
                    ),
                    // Danh sách thể loại đã được sắp xếp theo lượng tác phẩm nhiều nhất lên trước
                    ...sortedGenres.map((g) {
                      final isSelected = selectedGenre == g.name;
                      return _buildGenreTabItem(
                        label: g.name,
                        isSelected: isSelected,
                        colors: colors,
                        onTap: () {
                          if (_isGenreExpanded) setState(() => _isGenreExpanded = false);
                          ref
                              .read(searchViewModelProvider.notifier)
                              .filterByGenre(g.name);
                        },
                      );
                    }),
                  ],
                ),
              ),
              // Nút mũi tên mở rộng tương tự ảnh (Image 3)
              IconButton(
                icon: Icon(
                  _isGenreExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_right_rounded,
                  size: 22,
                  color: colors.textSecondary,
                ),
                tooltip: _isGenreExpanded ? 'Thu gọn' : 'Xem tất cả thể loại',
                onPressed: () {
                  setState(() {
                    _isGenreExpanded = !_isGenreExpanded;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenreTabItem({
    required String label,
    required bool isSelected,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isSelected
              ? Border(
                  bottom: BorderSide(
                    color: colors.primaryBrand,
                    width: 3.0,
                  ),
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? colors.primaryBrand : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Khung mở rộng thể loại dạng Dropdown Overlay chuẩn Wattpad (Image 3)
  /// Sử dụng 100% Design Tokens từ hệ thống (AppColors & AppDimensions)
  Widget _buildExpandedGenrePanel({
    required List<Genre> sortedGenres,
    required String? selectedGenre,
    required AppColors colors,
  }) {
    return Material(
      elevation: 6,
      color: colors.bgSurface,
      shadowColor: colors.textPrimary.withValues(alpha: 0.15),
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppDimensions.radiusLg),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppDimensions.radiusLg),
          ),
          border: Border(
            bottom: BorderSide(color: colors.borderDefault, width: 0.5),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.space4,
            AppDimensions.space3,
            AppDimensions.space3,
            AppDimensions.space5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppDimensions.space2,
                  runSpacing: AppDimensions.space2 + 2,
                  children: [
                    // Tab "Tất cả"
                    _buildPanelChip(
                      label: 'Tất cả',
                      isSelected: selectedGenre == null,
                      colors: colors,
                      onTap: () {
                        ref
                            .read(searchViewModelProvider.notifier)
                            .filterByGenre(null);
                        setState(() => _isGenreExpanded = false);
                      },
                    ),
                    // Danh sách thể loại đã được sắp xếp theo bảng chữ cái A-Z
                    ...sortedGenres.map((g) {
                      final isSelected = selectedGenre == g.name;
                      return _buildPanelChip(
                        label: g.name,
                        isSelected: isSelected,
                        colors: colors,
                        onTap: () {
                          ref
                              .read(searchViewModelProvider.notifier)
                              .filterByGenre(g.name);
                          setState(() => _isGenreExpanded = false);
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space2),
              // Nút ^ thu gọn ở góc trên bên phải
              IconButton(
                tooltip: 'Thu gọn danh mục',
                icon: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 26,
                  color: colors.textPrimary,
                ),
                onPressed: () => setState(() => _isGenreExpanded = false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chip thể loại trong khung mở rộng (Chuẩn hệ màu Warm Editorial):
  /// - Khi chọn: Nền màu chính (colors.textPrimary), chữ màu tương phản (colors.bgSurface), chữ đậm
  /// - Chưa chọn: Nền màu bề mặt dịu nhẹ (colors.bgSurfaceSubtle), chữ colors.textPrimary, viền borderDefault
  Widget _buildPanelChip({
    required String label,
    required bool isSelected,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    final chipBg = isSelected ? colors.textPrimary : colors.bgSurfaceSubtle;
    final textColor = isSelected ? colors.bgSurface : colors.textPrimary;
    final borderColor = isSelected ? colors.textPrimary : colors.borderDefault.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space3 + 2,
          vertical: AppDimensions.space2,
        ),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  /// 3. Dòng thống kê số lượng + Nút [Lọc] (Image 2)
  Widget _buildResultsHeader(int totalCount, AppColors colors) {
    final countText = _formatCount(totalCount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$countText Truyện',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        OutlinedButton.icon(
          icon: Icon(Icons.tune_rounded, size: 16, color: colors.textPrimary),
          label: Text(
            'Lọc',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            side: BorderSide(color: colors.borderDefault),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
          onPressed: () => SearchGenreBottomSheet.show(context),
        ),
      ],
    );
  }

  /// 4. Tile truyện xếp hạng (Rank 1, 2, 3...) theo chuẩn Wattpad (Image 2)
  /// Sử dụng dữ liệu thật từ API, không fake số view
  Widget _buildRankedBookTile({
    required int rank,
    required Series series,
    required AppColors colors,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: () {
        context.push(AppPaths.seriesDetail(series.id), extra: series);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Ảnh bìa truyện bên trái
          Container(
            width: 76,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: series.coverImageUrl.isNotEmpty
                  ? Image.network(
                      series.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildPlaceholderCover(colors),
                    )
                  : _buildPlaceholderCover(colors),
            ),
          ),

          const SizedBox(width: AppDimensions.space3),

          // B. Nội dung chi tiết bên phải
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Số thứ tự + Tên truyện
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$rank  ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // Tác giả
                Text(
                  series.authorName,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),

                const SizedBox(height: 6),

                // Thống kê:
                // CHỈ hiển thị viewCount nếu API thật sự có trả về viewCount, nếu không có thì BỎ
                Row(
                  children: [
                    if (series.viewCount != null) ...[
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 13,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatViews(series.viewCount!),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    if (series.totalChapters > 0) ...[
                      Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 13,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${series.totalChapters} chương',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ] else if (series.averageRating > 0) ...[
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: colors.accent,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        series.averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (series.totalRatings > 0) ...[
                        const SizedBox(width: 3),
                        Text(
                          '(${series.totalRatings})',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),

                const SizedBox(height: 6),

                // Danh sách Tags / Thể loại
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...series.genres.take(3).map(
                          (genre) => _buildTagPill(genre.toLowerCase(), colors),
                        ),
                    if (series.genres.length > 3)
                      _buildTagPill('+ truyện khác', colors),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagPill(String text, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bgSurfaceSubtle,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(AppColors colors) {
    return Container(
      color: colors.bgSurfaceSubtle,
      child: Center(
        child: Icon(
          Icons.auto_stories_rounded,
          size: 28,
          color: colors.primaryBrand.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(2).replaceAll('.', ',')}K';
    }
    return '$count';
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
    }
    if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1).replaceAll('.', ',')}K';
    }
    return '$views';
  }
}
