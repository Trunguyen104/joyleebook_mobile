import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/series.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../../notifications/widgets/notification_bell_button.dart';
import '../view_models/ai_recommendation_view_model.dart';
import '../view_models/series_list_view_model.dart';
import 'ai_recommendation_section.dart';

/// MÀN HÌNH TRANG CHỦ / KHO TRUYỆN (SeriesListScreen)
/// Phân loại và sắp xếp dựa trên THÔNG SỐ THẬT từ API:
/// 1. "Truyện tiếp theo bạn đọc": Ưu tiên truyện đã lưu trong Tủ sách (isBookmarked) hoặc thứ tự mặc định từ API.
/// 2. "Chúng tôi tin bạn sẽ thích": Sắp xếp theo điểm đánh giá thực tế (averageRating & totalRatings).
/// 3. "Thử đọc Truyện Mới": Sắp xếp theo ngày tạo (createdAt) mới nhất hoặc trạng thái đang tiến hành.
///
/// Tuyệt đối KHÔNG fake số liệu: Nếu API không trả viewCount thì ẩn hoàn toàn icon và lượt xem.
class SeriesListScreen extends ConsumerStatefulWidget {
  const SeriesListScreen({super.key});

  @override
  ConsumerState<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends ConsumerState<SeriesListScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final seriesState = ref.watch(seriesListViewModelProvider);

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
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Tìm kiếm & Khám phá',
            onPressed: () => context.go(AppPaths.search),
          ),
          const NotificationBellButton(),
        ],
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
          message: err is AppException
              ? err.message
              : 'Đã có lỗi xảy ra khi tải kho truyện.',
          onRetry: () =>
              ref.read(seriesListViewModelProvider.notifier).refresh(),
        ),

        // TRẠNG THÁI 3 & 4: CÓ DỮ LIỆU HOẶC DANH SÁCH RỖNG
        data: (seriesList) {
          // A. Danh sách rỗng -> Empty State
          if (seriesList.isEmpty) {
            return JoyleeEmptyState(
              title: 'Không tìm thấy truyện nào',
              message:
                  'Hiện tại chưa có tác phẩm nào được xuất bản trên hệ thống.',
              actionLabel: 'Tải lại toàn bộ',
              onAction: () =>
                  ref.read(seriesListViewModelProvider.notifier).refresh(),
            );
          }

          // B. SẮP XẾP DỰA TRÊN THÔNG SỐ THỰC TẾ TỪ API:
          // 1. "Truyện tiếp theo bạn đọc": Truyện độc giả đã đánh dấu (bookmark) hoặc thứ tự API
          final bookmarkedList = seriesList
              .where((s) => s.isBookmarked)
              .toList();
          final nextToReadList = bookmarkedList.isNotEmpty
              ? bookmarkedList
              : seriesList;

          // 2. "Chúng tôi tin bạn sẽ thích": Sắp xếp theo điểm đánh giá thật (averageRating) & tổng lượt vote (totalRatings)
          final topRatedList = List<Series>.from(seriesList)
            ..sort((a, b) {
              final ratingCmp = b.averageRating.compareTo(a.averageRating);
              if (ratingCmp != 0) return ratingCmp;
              return b.totalRatings.compareTo(a.totalRatings);
            });

          // 3. "Thử đọc Truyện Mới": Sắp xếp theo ngày tạo (createdAt) mới nhất hoặc trạng thái đang tiến hành
          final newestList = List<Series>.from(seriesList)
            ..sort((a, b) {
              if (a.createdAt != null && b.createdAt != null) {
                return b.createdAt!.compareTo(a.createdAt!);
              }
              if (a.createdAt != null) return -1;
              if (b.createdAt != null) return 1;
              // Nếu API chưa trả createdAt: ưu tiên truyện đang ra (ongoing) rồi đến id
              if (a.status == SeriesStatus.ongoing &&
                  b.status != SeriesStatus.ongoing) {
                return -1;
              }
              if (b.status == SeriesStatus.ongoing &&
                  a.status != SeriesStatus.ongoing) {
                return 1;
              }
              return b.id.compareTo(a.id);
            });

          // Nếu chỉ có 1 truyện trong kho dữ liệu (như môi trường test), chỉ hiện 1 mục chính tránh lặp
          final isSingleItem = seriesList.length <= 1;

          return RefreshIndicator(
            color: colors.primaryBrand,
            backgroundColor: colors.bgSurface,
            onRefresh: () async {
              await Future.wait([
                ref.read(seriesListViewModelProvider.notifier).refresh(),
                ref.read(aiRecommendationViewModelProvider.notifier).refresh(),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.space2,
              ),
              children: [
                // SECTION AI: Gợi ý truyện bằng AI (Gemini Embedding + Qdrant Vector Search)
                const AiRecommendationSection(),
                const SizedBox(height: AppDimensions.space4),

                // SECTION 1: Truyện tiếp theo bạn đọc
                _buildSection(
                  title: 'Truyện tiếp theo bạn đọc',
                  seriesList: nextToReadList,
                  colors: colors,
                ),

                if (!isSingleItem) ...[
                  const SizedBox(height: AppDimensions.space4),
                  // SECTION 2: Chúng tôi tin bạn sẽ thích (Đánh giá cao nhất từ API)
                  _buildSection(
                    title: 'Chúng tôi tin bạn sẽ thích',
                    seriesList: topRatedList,
                    colors: colors,
                  ),

                  const SizedBox(height: AppDimensions.space4),
                  // SECTION 3: Thử đọc Truyện Mới (Ngày tạo mới nhất)
                  _buildSection(
                    title: 'Thử đọc Truyện Mới',
                    seriesList: newestList,
                    colors: colors,
                  ),
                ],

                const SizedBox(height: AppDimensions.space5),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Khung hiển thị một Section cuộn ngang
  Widget _buildSection({
    required String title,
    required List<Series> seriesList,
    required AppColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space3),
        SizedBox(
          height: 310,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space4,
            ),
            itemCount: seriesList.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppDimensions.space3),
            itemBuilder: (context, index) {
              final series = seriesList[index];
              return _buildBookCard(series, colors);
            },
          ),
        ),
      ],
    );
  }

  /// Card truyện cuộn ngang theo chuẩn Wattpad (Image 1)
  /// Sử dụng dữ liệu thật từ API, không fake số view
  Widget _buildBookCard(Series series, AppColors colors) {
    final displayTags = series.genres.isNotEmpty
        ? series.genres.take(2).map(_capitalizeGenre).toList()
        : [series.status == SeriesStatus.completed ? 'Hoàn Thành' : 'Đang Ra'];

    return InkWell(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onTap: () {
        context.push(AppPaths.seriesDetail(series.id), extra: series);
      },
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh bìa truyện đứng (Aspect Ratio ~2:3)
            Container(
              width: 120,
              height: 165,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
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
                            _buildPlaceholderCover(colors),
                      )
                    : _buildPlaceholderCover(colors),
              ),
            ),

            const SizedBox(height: 6),

            // 2. Tag danh mục thể loại (Hiển thị tối đa 2 thể loại cùng 1 hàng, tự động cắt ... nếu dài)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < displayTags.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: displayTags.length > 1 ? 56 : 85,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgSurfaceSubtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        displayTags[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 4),

            // 3. Số lượt xem (CHỈ hiển thị nếu API có trả về viewCount, nếu không có thì BỎ HOÀN TOÀN)
            if (series.viewCount != null) ...[
              Row(
                children: [
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
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ] else if (series.averageRating > 0) ...[
              // Nếu không có view nhưng có rating thật từ API thì hiển thị điểm đánh giá thật
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
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
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
            ],

            // 4. Tiêu đề và Tác giả (hiển thị đầy đủ tiêu đề)
            Text(
              series.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              series.authorName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
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
          size: 36,
          color: colors.primaryBrand.withValues(alpha: 0.5),
        ),
      ),
    );
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

  String _capitalizeGenre(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }
}
