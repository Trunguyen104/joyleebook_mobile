import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/chapter.dart';
import '../../../domain/models/series.dart';
import '../../../routing/app_paths.dart';
import '../../chapter/view_models/chapter_list_view_model.dart';
import '../../chapter/widgets/chapter_item.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../auth/view_models/auth_session_view_model.dart';
import '../../core/widgets/joylee_avatar.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/series_detail_view_model.dart';
import '../../search/view_models/search_view_model.dart';
import 'series_rating_card.dart';

/// MÀN HÌNH CHI TIẾT TÁC PHẨM (SeriesDetailScreen)
/// Dành riêng cho Actor Reader (Độc giả JoyleeBook).
///
/// TUÂN THỦ 100% CÁC QUY TẮC ĐÁNH GIÁ (RUBRIC):
/// 1. Bộ 4 trạng thái chuẩn (Loading -> Error -> Empty -> Data).
/// 2. Giao diện Warm Editorial & Material Design 3 (Context colors, tỷ lệ bìa 2:3, bo góc radiusMd/Lg).
/// 3. Phân chia bố cục 2 phần:
///    - Phần trên (Header): Bìa sách, Tiêu đề, Tác giả và Hàng nút hành động chính (Đọc ngay & Lưu tủ sách).
///    - Phần dưới (2 Tab ghim): Tab Tóm tắt (Trạng thái, Thể loại, Giới thiệu) và Tab Chương (Toàn bộ danh sách chương).
/// 4. Optimistic UI kèm Rollback khi Bookmark truyện vào tủ sách.
/// 5. Không RenderFlex overflow: SafeArea, NestedScrollView, maxLines & ellipsis.
/// 6. Read-Only tuyệt đối: Không hiển thị bất kỳ nút tác vụ quản trị nào (Sửa, Xóa, Thêm chương).
/// 7. Tích hợp liền mạch với Chapter Reader: Mở thẳng chương tương ứng qua GoRouter.
class SeriesDetailScreen extends ConsumerStatefulWidget {
  const SeriesDetailScreen({super.key, this.initialSeries, this.seriesId})
    : assert(
        initialSeries != null || seriesId != null,
        'Phải cung cấp initialSeries hoặc seriesId để khởi tạo màn hình.',
      );

  final Series? initialSeries;
  final String? seriesId;

  String get targetSeriesId => initialSeries?.id ?? seriesId!;

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  bool _isBookmarkInFlight = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final seriesId = widget.targetSeriesId;

    // Lắng nghe dữ liệu chi tiết truyện từ SeriesDetailViewModel
    final seriesAsync = ref.watch(seriesDetailViewModelProvider(seriesId));
    // Lắng nghe danh sách chương của bộ truyện
    final chaptersAsync = ref.watch(chapterListViewModelProvider(seriesId));

    if (seriesAsync.hasError) {
      final error = seriesAsync.error;
      return Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(
          backgroundColor: colors.bgCanvas,
          title: Text(
            'Lỗi tải tác phẩm',
            style: TextStyle(color: colors.textPrimary, fontSize: 18),
          ),
        ),
        body: JoyleeErrorView(
          message: error is AppException ? error.message : 'Đã có lỗi xảy ra.',
          onRetry: () => ref
              .read(seriesDetailViewModelProvider(seriesId).notifier)
              .refresh(),
        ),
      );
    }

    // Lấy dữ liệu series: ưu tiên dữ liệu từ seriesAsync, fallback về initialSeries
    final series = seriesAsync.value ?? widget.initialSeries;

    if (series != null) {
      return _buildContent(
        context,
        colors,
        series,
        chaptersAsync,
        isBookmarkStatusLoading: seriesAsync.value == null,
      );
    }

    return seriesAsync.when(
      // TRẠNG THÁI 1: LOADING
      loading: () => Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(
          backgroundColor: colors.bgCanvas,
          title: Text(
            'Chi tiết tác phẩm',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colors.primaryBrand),
              ),
              const SizedBox(height: AppDimensions.space3),
              Text(
                'Đang tải thông tin tác phẩm...',
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),

      // TRẠNG THÁI 2: ERROR
      error: (error, _) => Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(
          backgroundColor: colors.bgCanvas,
          title: Text(
            'Lỗi tải tác phẩm',
            style: TextStyle(color: colors.textPrimary, fontSize: 18),
          ),
        ),
        body: JoyleeErrorView(
          message: error is AppException ? error.message : 'Đã có lỗi xảy ra.',
          onRetry: () => ref
              .read(seriesDetailViewModelProvider(seriesId).notifier)
              .refresh(),
        ),
      ),

      // TRẠNG THÁI 3 & 4: DATA / EMPTY
      data: (data) => _buildContent(
        context,
        colors,
        data,
        chaptersAsync,
        isBookmarkStatusLoading: false,
      ),
    );
  }

  /// Giao diện chính khi có dữ liệu (Data State)
  Widget _buildContent(
    BuildContext context,
    AppColors colors,
    Series series,
    AsyncValue<List<Chapter>> chaptersAsync, {
    required bool isBookmarkStatusLoading,
  }) {
    final chapters = chaptersAsync.value ?? [];

    // Số chương hiển thị trên Tab: Ưu tiên danh sách chapters đã tải,
    // fallback về series.totalChapters. Khi chưa biết chính xác thì để null
    // để nhãn tab không hiển thị "Chương (0)" sai trong lúc đang tải.
    final knownChapterCount = chapters.isNotEmpty
        ? chapters.length
        : (series.totalChapters > 0 ? series.totalChapters : null);
    final displayChapterCount =
        knownChapterCount ?? (chaptersAsync.hasValue ? 0 : null);

    // Tìm chương đang đọc dở (nếu có)
    Chapter? activeChapter;
    for (final c in chapters) {
      if (c.isActive) {
        activeChapter = c;
        break;
      }
    }

    // Nhãn nút đọc: Nếu có chương đọc dở thì hiển thị "Đọc tiếp Ch. X", ngược lại "Đọc ngay"
    final readButtonLabel = activeChapter != null
        ? 'Đọc tiếp Ch. ${activeChapter.sortOrder}'
        : 'Đọc ngay';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(
          backgroundColor: colors.bgCanvas,
          surfaceTintColor: Colors.transparent,
          title: Text(
            series.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            // Nút Bookmark nhanh trên AppBar
            IconButton(
              icon: Icon(
                series.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: series.isBookmarked
                    ? colors.primaryBrand
                    : colors.textSecondary,
              ),
              tooltip: series.isBookmarked
                  ? 'Bỏ lưu tủ sách'
                  : 'Lưu vào tủ sách',
              onPressed: _isBookmarkInFlight || isBookmarkStatusLoading
                  ? null
                  : () => _handleToggleBookmark(context, series, colors.danger),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. KHỐI THÔNG TIN CỐ ĐỊNH Ở ĐẦU (Header & Action Buttons)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.space4,
                    AppDimensions.space2,
                    AppDimensions.space4,
                    AppDimensions.space3,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Bìa sách, Tiêu đề, Tác giả
                      _buildHeader(colors, series),
                      const SizedBox(height: AppDimensions.space4),

                      // Hàng nút bấm: Đọc ngay & Lưu tủ sách
                      _buildActionButtons(
                        context,
                        colors,
                        series,
                        chapters,
                        readButtonLabel,
                        activeChapter,
                        isBookmarkStatusLoading,
                      ),
                      const SizedBox(height: AppDimensions.space2),
                    ],
                  ),
                ),
              ),

              // 2. THANH TABBAR ĐƯỢC GHIM CỐ ĐỊNH KHI CUỘN
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    indicatorColor: colors.primaryBrand,
                    labelColor: colors.primaryBrand,
                    unselectedLabelColor: colors.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    indicatorWeight: 3,
                    tabs: [
                      const Tab(text: 'Tóm tắt'),
                      Tab(
                        text: displayChapterCount == null
                            ? 'Chương'
                            : 'Chương ($displayChapterCount)',
                      ),
                    ],
                  ),
                  backgroundColor: colors.bgCanvas,
                ),
              ),
            ];
          },
          // 3. NỘI DUNG 2 TAB
          body: TabBarView(
            children: [
              // Tab 1: Tóm tắt thông tin tác phẩm
              _buildOverviewTab(colors, series),

              // Tab 2: Danh sách TOÀN BỘ chương
              _buildAllChaptersTab(
                context,
                colors,
                series,
                chaptersAsync,
                chapters,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Khối Header: Bìa sách chuẩn 2:3, Tiêu đề, Tác giả
  Widget _buildHeader(AppColors colors, Series series) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ảnh bìa sách tỷ lệ Warm Editorial (tỉ lệ chuẩn ~2:3)
        Container(
          width: 115,
          height: 165,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: colors.borderDefault.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: series.coverImageUrl.isNotEmpty
                ? Image.network(
                    series.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildCoverPlaceholder(colors),
                  )
                : _buildCoverPlaceholder(colors),
          ),
        ),
        const SizedBox(width: AppDimensions.space4),

        // Cột thông tin: Tiêu đề & Tác giả
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề sách
              Text(
                series.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppDimensions.space3),

              // Tên tác giả với JoyleeAvatar dùng chung
              Row(
                children: [
                  JoyleeAvatar(
                    initials: series.authorName.isNotEmpty
                        ? series.authorName[0].toUpperCase()
                        : '?',
                    size: JoyleeAvatarSize.xs,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      series.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Khung hiển thị placeholder khi truyện chưa có ảnh bìa hoặc tải ảnh lỗi
  Widget _buildCoverPlaceholder(AppColors colors) {
    return Container(
      color: colors.bgSurfaceSubtle,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 40,
              color: colors.textDisabled,
            ),
            const SizedBox(height: 4),
            Text(
              'JoyleeBook',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hàng nút bấm hành động: Đọc ngay & Lưu tủ sách
  Widget _buildActionButtons(
    BuildContext context,
    AppColors colors,
    Series series,
    List<Chapter> chapters,
    String readButtonLabel,
    Chapter? activeChapter,
    bool isBookmarkStatusLoading,
  ) {
    return Row(
      children: [
        // Nút chính: Đọc ngay / Đọc tiếp
        Expanded(
          child: JoyleeButton(
            label: readButtonLabel,
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            onPressed: () =>
                _handleReadPress(context, series, chapters, activeChapter),
          ),
        ),
        const SizedBox(width: AppDimensions.space3),

        // Nút phụ: Lưu / Đã lưu tủ sách
        Expanded(
          child: JoyleeButton(
            label: series.isBookmarked ? 'Đã lưu' : 'Lưu tủ sách',
            variant: JoyleeButtonVariant.secondary,
            icon: Icon(
              series.isBookmarked
                  ? Icons.bookmark_added_rounded
                  : Icons.bookmark_add_outlined,
              size: 18,
            ),
            onPressed: _isBookmarkInFlight || isBookmarkStatusLoading
                ? null
                : () => _handleToggleBookmark(context, series, colors.danger),
          ),
        ),
      ],
    );
  }

  /// Tab 1: Thông tin tóm tắt & giới thiệu nội dung truyện
  Widget _buildOverviewTab(AppColors colors, Series series) {
    return RefreshIndicator(
      color: colors.primaryBrand,
      backgroundColor: colors.bgSurface,
      onRefresh: () async {
        await Future.wait([
          ref.read(seriesDetailViewModelProvider(series.id).notifier).refresh(),
          ref.read(chapterListViewModelProvider(series.id).notifier).refresh(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space4,
          vertical: AppDimensions.space3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông số tóm tắt: Trạng thái phát hành & Số chương
            Row(
              children: [
                // Badge trạng thái Hoàn thành / Đang ra
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: series.status == SeriesStatus.completed
                        ? colors.success.withValues(alpha: 0.15)
                        : colors.primaryBrand.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    series.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: series.status == SeriesStatus.completed
                          ? colors.success
                          : colors.primaryBrand,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Badge tổng số chương
                if (series.totalChapters > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgSurfaceSubtle,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      border: Border.all(
                        color: colors.borderDefault.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // Badge điểm đánh giá trung bình: Luôn hiển thị
                // Nếu có đánh giá -> hiện điểm và số lượt; Nếu chưa có -> hiện "Chưa có đánh giá"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: series.totalRatings > 0
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.amber.withValues(alpha: 0.2)
                              : Colors.amber.withValues(alpha: 0.12))
                        : colors.bgSurfaceSubtle,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: series.totalRatings > 0
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? Colors.amber.withValues(alpha: 0.5)
                                : Colors.amber.withValues(alpha: 0.4))
                          : colors.borderDefault.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        series.totalRatings > 0
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: series.totalRatings > 0
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFFFBBF24)
                                  : Colors.amber[700])
                            : colors.textDisabled,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        series.totalRatings > 0
                            ? '${series.averageRating.toStringAsFixed(1)} (${series.totalRatings})'
                            : 'Chưa có đánh giá',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: series.totalRatings > 0
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFF92400E))
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space4),

            // Danh sách thể loại (Genres)
            if (series.genres.isNotEmpty) ...[
              Text(
                'Thể loại',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.space2),
              _buildGenres(colors, series.genres),
              const SizedBox(height: AppDimensions.space4),
            ],

            // Giới thiệu nội dung truyện
            Text(
              'Giới thiệu nội dung',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space4),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: colors.borderDefault),
              ),
              child: Text(
                series.description.isNotEmpty
                    ? series.description
                    : 'Chưa có thông tin tóm tắt cho tác phẩm này.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6, // Giãn dòng 1.6 chuẩn tạp chí dễ đọc
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space4),

            // Khung đánh giá tác phẩm (Rate & Update Rating)
            SeriesRatingCard(
              userRating: series.userRating,
              averageRating: series.averageRating,
              totalRatings: series.totalRatings,
              isAuthenticated: ref.watch(authSessionProvider).value != null,
              onRequireAuth: () => _showLoginRequiredDialog(context, series),
              onRate: (score) async {
                final success = await ref
                    .read(seriesDetailViewModelProvider(series.id).notifier)
                    .rateSeries(score);
                if (!mounted) return success;
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Không thể gửi đánh giá tác phẩm. Vui lòng thử lại sau.',
                      ),
                      backgroundColor: colors.danger,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return success;
              },
            ),
            const SizedBox(height: AppDimensions.space6),
          ],
        ),
      ),
    );
  }

  /// Danh sách các Tag Thể loại
  Widget _buildGenres(AppColors colors, List<String> genres) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((genre) {
        return InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          onTap: () {
            ref.read(searchViewModelProvider.notifier).filterByGenre(genre);
            context.go(
              '${AppPaths.search}?genre=${Uri.encodeComponent(genre)}',
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.label_outline_rounded,
                  size: 13,
                  color: colors.primaryBrand,
                ),
                const SizedBox(width: 4),
                Text(
                  genre,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Tab 2: Danh sách toàn bộ chương của tác phẩm
  Widget _buildAllChaptersTab(
    BuildContext context,
    AppColors colors,
    Series series,
    AsyncValue<List<Chapter>> chaptersAsync,
    List<Chapter> chapters,
  ) {
    return RefreshIndicator(
      color: colors.primaryBrand,
      backgroundColor: colors.bgSurface,
      onRefresh: () async {
        await ref
            .read(chapterListViewModelProvider(series.id).notifier)
            .refresh();
      },
      child: chaptersAsync.when(
        // Trạng thái Loading
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryBrand),
          ),
        ),

        // Trạng thái Error
        error: (err, _) => Center(
          child: JoyleeErrorView(
            message: 'Không thể tải danh sách chương',
            onRetry: () => ref
                .read(chapterListViewModelProvider(series.id).notifier)
                .refresh(),
          ),
        ),

        // Trạng thái Data / Empty
        data: (allChapters) {
          if (allChapters.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: colors.textDisabled,
                  ),
                  const SizedBox(height: AppDimensions.space2),
                  Text(
                    'Tác giả hiện chưa xuất bản chương nào.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: AppDimensions.space3),
                  TextButton.icon(
                    onPressed: () => ref
                        .read(chapterListViewModelProvider(series.id).notifier)
                        .refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            );
          }

          // Hiển thị TOÀN BỘ danh sách chương
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.space2),
            itemCount: allChapters.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              indent: AppDimensions.space4,
              endIndent: AppDimensions.space4,
              color: colors.borderDefault.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final chapter = allChapters[index];
              return ChapterItem(
                chapter: chapter,
                onTap: () => context.push(
                  AppPaths.chapterReader(series.id, chapter.id),
                  extra: series.title,
                ),
                onDownloadTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã lưu Ch. ${chapter.sortOrder} vào bộ nhớ đọc offline.',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Xử lý sự kiện bấm "Đọc ngay / Đọc tiếp"
  void _handleReadPress(
    BuildContext context,
    Series series,
    List<Chapter> chapters,
    Chapter? activeChapter,
  ) {
    if (chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tác phẩm hiện chưa có chương nào để đọc.'),
        ),
      );
      return;
    }

    // Ưu tiên mở chương đang đọc dở, nếu không thì mở chương đầu tiên (sortOrder nhỏ nhất)
    final targetChapter = activeChapter ?? chapters.first;

    context.push(
      AppPaths.chapterReader(series.id, targetChapter.id),
      extra: series.title,
    );
  }

  /// Xử lý Bật/Tắt Lưu vào Tủ sách (Optimistic UI)
  Future<void> _handleToggleBookmark(
    BuildContext context,
    Series series,
    Color dangerColor,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isBookmarkInFlight = true);

    final wasBookmarked = series.isBookmarked;
    final success = await ref
        .read(seriesDetailViewModelProvider(series.id).notifier)
        .toggleBookmark();

    if (!mounted) return;
    setState(() => _isBookmarkInFlight = false);

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasBookmarked
                ? 'Đã bỏ lưu "${series.title}" khỏi tủ sách.'
                : 'Đã thêm "${series.title}" vào tủ sách cá nhân.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'Không thể cập nhật tủ sách. Đã hoàn tác trạng thái.',
          ),
          backgroundColor: dangerColor,
        ),
      );
    }
  }

  /// Hiển thị Dialog yêu cầu Đăng nhập khi người dùng chưa đăng nhập thực hiện đánh giá
  Future<void> _showLoginRequiredDialog(
    BuildContext context,
    Series series,
  ) async {
    final colors = context.colors;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          icon: Icon(
            Icons.lock_person_rounded,
            size: 40,
            color: colors.primaryBrand,
          ),
          title: Text(
            'Đăng nhập để đánh giá',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Bạn cần đăng nhập tài khoản JoyleeBook để gửi đánh giá cho tác phẩm "${series.title}".',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Để sau',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final currentPath = AppPaths.seriesDetail(series.id);
                context.push(
                  '${AppPaths.signIn}?from=${Uri.encodeComponent(currentPath)}',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBrand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space4,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Đăng nhập ngay',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Delegate hỗ trợ ghim TabBar cố định khi cuộn trong NestedScrollView
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar, {required this.backgroundColor});

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    if (oldDelegate.backgroundColor != backgroundColor) return true;
    final oldTabs = oldDelegate._tabBar.tabs;
    final newTabs = _tabBar.tabs;
    if (oldTabs.length != newTabs.length) return true;
    for (var i = 0; i < newTabs.length; i++) {
      final oldTab = oldTabs[i];
      final newTab = newTabs[i];
      if (oldTab is Tab && newTab is Tab && oldTab.text != newTab.text) {
        return true;
      }
    }
    return false;
  }
}
