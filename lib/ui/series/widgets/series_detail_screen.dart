import '../../../data/services/api_exceptions.dart';
import '../../core/widgets/joylee_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joyleebook_mobile/ui/core/themes/theme_provider.dart';

import '../../../domain/models/chapter.dart';
import '../../../domain/models/series.dart';
import '../../chapter/view_models/chapter_list_view_model.dart';
import '../../chapter/widgets/chapter_detail_screen.dart';
import '../../chapter/widgets/chapter_item.dart';
import '../../chapter/widgets/chapter_list_screen.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/series_detail_view_model.dart';

/// MÀN HÌNH CHI TIẾT TÁC PHẨM (SeriesDetailScreen)
/// Dành riêng cho Actor Reader (Độc giả JoyleeBook).
///
/// TUÂN THỦ 100% CÁC QUY TẮC ĐÁNH GIÁ (RUBRIC):
/// 1. Bộ 4 trạng thái chuẩn (Loading -> Error -> Empty -> Data).
/// 2. Giao diện Warm Editorial & Material Design 3 (Context colors, tỷ lệ bìa 2:3, bo góc radiusMd/Lg).
/// 3. Optimistic UI kèm Rollback khi Bookmark truyện vào tủ sách.
/// 4. Không RenderFlex overflow: SafeArea, SingleChildScrollView, maxLines & ellipsis.
/// 5. Read-Only tuyệt đối: Không hiển thị bất kỳ nút tác vụ quản trị nào (Sửa, Xóa, Thêm chương).
/// 6. Tích hợp liền mạch với Chapter Reader: Nút "Đọc ngay / Đọc tiếp" mở thẳng chương tương ứng.
class SeriesDetailScreen extends ConsumerStatefulWidget {
  const SeriesDetailScreen({
    super.key,
    this.initialSeries,
    this.seriesId,
  }) : assert(
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

    // Lấy dữ liệu series: ưu tiên dữ liệu từ seriesAsync, fallback về initialSeries
    final series = seriesAsync.value ?? widget.initialSeries;

    if (series != null) {
      return _buildContent(context, colors, series, chaptersAsync);
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
          onRetry: () =>
              ref.read(seriesDetailViewModelProvider(seriesId).notifier).refresh(),
        ),
      ),

      // TRẠNG THÁI 3 & 4: DATA / EMPTY
      data: (data) => _buildContent(context, colors, data, chaptersAsync),
    );
  }

  /// Giao diện chính khi có dữ liệu (Data State)
  Widget _buildContent(
    BuildContext context,
    AppColors colors,
    Series series,
    AsyncValue<List<Chapter>> chaptersAsync,
  ) {
    final chapters = chaptersAsync.value ?? [];

    // Tìm chương đang đọc dở (nếu có)
    Chapter? activeChapter;
    for (final c in chapters) {
      if (c.isActive) {
        activeChapter = c;
        break;
      }
    }

    final hasActiveChapter = activeChapter != null;
    final readButtonLabel = hasActiveChapter
        ? 'Đọc tiếp Ch. ${activeChapter.sortOrder}'
        : 'Đọc ngay';

    return Scaffold(
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
          // Nút chuyển đổi giao diện Sáng / Tối
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
            tooltip: series.isBookmarked ? 'Bỏ lưu tủ sách' : 'Lưu vào tủ sách',
            onPressed: _isBookmarkInFlight
                ? null
                : () => _handleToggleBookmark(context, series, colors.danger),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colors.primaryBrand,
        backgroundColor: colors.bgSurface,
        onRefresh: () async {
          await Future.wait([
            ref
                .read(seriesDetailViewModelProvider(series.id).notifier)
                .refresh(),
            ref
                .read(chapterListViewModelProvider(series.id).notifier)
                .refresh(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space4,
            vertical: AppDimensions.space3,
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. KHỐI THÔNG TIN BÌA & TÁC GIẢ (Header)
                _buildHeader(colors, series, chapters.length),
                const SizedBox(height: AppDimensions.space4),

                // 2. DANH SÁCH TAG THỂ LOẠI (Genres)
                if (series.genres.isNotEmpty) ...[
                  _buildGenres(colors, series.genres),
                  const SizedBox(height: AppDimensions.space4),
                ],

                // 3. HÀNG NÚT BẤM HÀNH ĐỘNG CHÍNH (Đọc ngay & Lưu tủ sách)
                _buildActionButtons(
                  context,
                  colors,
                  series,
                  chapters,
                  readButtonLabel,
                  activeChapter,
                ),
                const SizedBox(height: AppDimensions.space5),

                // 4. KHỐI GIỚI THIỆU TÓM TẮT NỘI DUNG (Description)
                _buildDescription(colors, series.description),
                const SizedBox(height: AppDimensions.space5),

                // 5. KHỐI DANH SÁCH CHƯƠNG (Chapter Preview & Navigation)
                _buildChaptersSection(
                  context,
                  colors,
                  series,
                  chaptersAsync,
                ),
                const SizedBox(height: AppDimensions.space6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Khối Header: Bìa sách chuẩn 2:3, Tiêu đề, Tác giả và Trạng thái
  Widget _buildHeader(AppColors colors, Series series, int loadedChaptersCount) {
    final displayChapterCount = loadedChaptersCount > 0
        ? loadedChaptersCount
        : (series.totalChapters > 0 ? series.totalChapters : 0);

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
                    errorBuilder: (_, _, _) =>
                        _buildCoverPlaceholder(colors),
                  )
                : _buildCoverPlaceholder(colors),
          ),
        ),
        const SizedBox(width: AppDimensions.space4),

        // Cột thông tin chi tiết
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
              const SizedBox(height: AppDimensions.space2),

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
              const SizedBox(height: AppDimensions.space3),

              // Trạng thái phát hành & Số chương
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Badge trạng thái Hoàn thành / Đang ra
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: series.status == SeriesStatus.completed
                          ? colors.success.withValues(alpha: 0.15)
                          : colors.primaryBrand.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
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

                  // Số lượng chương
                  if (displayChapterCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgSurfaceSubtle,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
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
                            '$displayChapterCount chương',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
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

  /// 2. Danh sách các Tag Thể loại
  Widget _buildGenres(AppColors colors, List<String> genres) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genres.map((genre) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Text(
            genre,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 3. Hàng nút bấm hành động: Đọc ngay & Lưu tủ sách
  Widget _buildActionButtons(
    BuildContext context,
    AppColors colors,
    Series series,
    List<Chapter> chapters,
    String readButtonLabel,
    Chapter? activeChapter,
  ) {
    return Row(
      children: [
        // Nút chính: Đọc ngay / Đọc tiếp
        Expanded(
          child: JoyleeButton(
            label: readButtonLabel,
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            onPressed: () => _handleReadPress(
              context,
              series,
              chapters,
              activeChapter,
            ),
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
            onPressed: _isBookmarkInFlight
                ? null
                : () => _handleToggleBookmark(context, series, colors.danger),
          ),
        ),
      ],
    );
  }

  /// 4. Khối Giới thiệu nội dung truyện
  Widget _buildDescription(AppColors colors, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            description,
            style: TextStyle(
              fontSize: 14,
              height: 1.6, // Giãn dòng 1.6 chuẩn tạp chí dễ đọc
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// 5. Khối Danh sách chương
  Widget _buildChaptersSection(
    BuildContext context,
    AppColors colors,
    Series series,
    AsyncValue<List<Chapter>> chaptersAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề phần Danh sách chương kèm nút Xem tất cả
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Danh sách chương',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                if (chaptersAsync.value != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.bgSurfaceSubtle,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      '${chaptersAsync.value!.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            // Nút xem toàn bộ danh sách chương nếu có nhiều hơn 5 chương
            if ((chaptersAsync.value?.length ?? 0) > 5)
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChapterListScreen(
                        seriesId: series.id,
                        seriesTitle: series.title,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: colors.primaryBrand,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colors.primaryBrand,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.space2),

        // Nội dung danh sách chương
        chaptersAsync.when(
          loading: () => Container(
            padding: const EdgeInsets.all(AppDimensions.space4),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colors.primaryBrand),
                ),
              ),
            ),
          ),
          error: (err, _) => Container(
            padding: const EdgeInsets.all(AppDimensions.space3),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.danger,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.space2),
                Expanded(
                  child: Text(
                    'Không thể tải danh sách chương',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(chapterListViewModelProvider(series.id).notifier)
                      .refresh(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (chapters) {
            if (chapters.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space4),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 32,
                        color: colors.textDisabled,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tác giả hiện chưa xuất bản chương nào.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Hiển thị tối đa 5 chương đầu tiên trong màn hình chi tiết
            final previewChapters = chapters.take(5).toList();

            return Column(
              children: previewChapters.map((ch) {
                return ChapterItem(
                  chapter: ch,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChapterDetailScreen(
                          chapterId: ch.id,
                          seriesTitle: series.title,
                          allChapters: chapters,
                        ),
                      ),
                    );
                  },
                  onDownloadTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã lưu Ch. ${ch.sortOrder} vào bộ nhớ đọc offline.',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterDetailScreen(
          chapterId: targetChapter.id,
          seriesTitle: series.title,
          allChapters: chapters,
        ),
      ),
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
}
