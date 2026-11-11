import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/ai_recommendation.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../view_models/ai_recommendation_view_model.dart';
import 'ai_custom_prompt_bottom_sheet.dart';

/// WIDGET SECTION - Khối gợi ý truyện bằng AI trên Trang chủ
class AiRecommendationSection extends ConsumerWidget {
  const AiRecommendationSection({super.key});

  static const List<Map<String, String>> _quickChips = [
    {'label': 'Tu tiên', 'prompt': 'truyện tiên hiệp tu chân phi thăng'},
    {'label': 'Kỳ ảo', 'prompt': 'truyện kỳ ảo phép thuật dị giới huyền bí'},
    {'label': 'Hành động', 'prompt': 'truyện hành động võ thuật kịch tính'},
    {
      'label': 'Ngôn tình',
      'prompt': 'truyện ngôn tình ngọt sủng tình cảm sâu sắc',
    },
    {'label': 'Trinh thám', 'prompt': 'truyện trinh thám đấu trí phá án ly kỳ'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final aiState = ref.watch(aiRecommendationViewModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Tiêu đề khối AI
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
          child: _buildHeader(context, ref, colors, aiState.value),
        ),
        const SizedBox(height: AppDimensions.space2),

        // 2. Thanh Chip đổi gu đọc nhanh
        _buildChipsRow(context, ref, colors, aiState.value),
        const SizedBox(height: AppDimensions.space3),

        // 3. Nội dung danh sách theo 4 trạng thái
        aiState.when(
          loading: () => _buildLoadingState(colors),
          error: (err, stack) => _buildErrorState(ref, colors, err),
          data: (state) {
            if (state.items.isEmpty) {
              return _buildEmptyState(ref, colors);
            }
            return _buildDataList(context, colors, state.items);
          },
        ),
      ],
    );
  }

  /// Tiêu đề section
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
    AiRecommendationState? state,
  ) {
    String title = 'AI Gợi ý cho bạn';
    String subtitle = 'Đề xuất thông minh bởi Qdrant & Gemini AI';

    if (state != null) {
      if (state.sourceSeriesTitle != null &&
          state.sourceSeriesTitle!.isNotEmpty) {
        title = 'Vì bạn đã đọc «${state.sourceSeriesTitle}»';
        subtitle = 'Các tác phẩm tương đồng về phong cách & cốt truyện';
      } else if (state.activeChip != null) {
        title = 'Gợi ý AI: Gu ${state.activeChip}';
        subtitle = 'Tuyển chọn từ khóa ngữ nghĩa phù hợp nhất';
      } else if (state.activePrompt != null) {
        title = 'Gợi ý AI theo yêu cầu riêng';
        subtitle = 'Phù hợp với mô tả bạn tìm kiếm';
      }
    }

    final hasFilter = state?.activePrompt != null || state?.activeChip != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Badge biểu tượng AI Sparkles
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primaryBrand, colors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
        ),
        const SizedBox(width: AppDimensions.space3),

        // Văn bản tiêu đề
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ),

        // Nút khôi phục hoặc làm mới
        if (hasFilter)
          TextButton(
            onPressed: () => ref
                .read(aiRecommendationViewModelProvider.notifier)
                .resetToDefault(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Mặc định',
              style: TextStyle(
                fontSize: 12,
                color: colors.primaryBrand,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: colors.textSecondary,
            ),
            tooltip: 'Làm mới gợi ý AI',
            onPressed: () =>
                ref.read(aiRecommendationViewModelProvider.notifier).refresh(),
          ),
      ],
    );
  }

  /// Thanh chip đổi gu đọc nhanh
  Widget _buildChipsRow(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
    AiRecommendationState? state,
  ) {
    final activeChip = state?.activeChip;
    final isDefault =
        activeChip == null &&
        (state?.activePrompt == null || state!.activePrompt!.isEmpty);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
      child: Row(
        children: [
          // Chip "Tất cả"
          FilterChip(
            selected: isDefault,
            label: const Text('Gợi ý cho bạn'),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
              color: isDefault ? colors.textOnBrand : colors.textPrimary,
            ),
            backgroundColor: colors.bgSurfaceSubtle,
            selectedColor: colors.primaryBrand,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              side: BorderSide(
                color: isDefault ? colors.primaryBrand : colors.borderDefault,
              ),
            ),
            onSelected: (_) {
              if (!isDefault) {
                ref
                    .read(aiRecommendationViewModelProvider.notifier)
                    .resetToDefault();
              }
            },
          ),
          const SizedBox(width: 8),

          // Các chip thể loại nhanh
          ..._quickChips.map((chip) {
            final isSelected = activeChip == chip['label'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(chip['label']!),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colors.textOnBrand : colors.textPrimary,
                ),
                backgroundColor: colors.bgSurfaceSubtle,
                selectedColor: colors.primaryBrand,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  side: BorderSide(
                    color: isSelected
                        ? colors.primaryBrand
                        : colors.borderDefault,
                  ),
                ),
                onSelected: (_) {
                  ref
                      .read(aiRecommendationViewModelProvider.notifier)
                      .filterByPrompt(
                        chip['prompt']!,
                        chipLabel: chip['label'],
                      );
                },
              ),
            );
          }),

          // Chip "✨ Nhập gu riêng..."
          ActionChip(
            avatar: Icon(
              Icons.edit_note_rounded,
              size: 16,
              color: colors.accent,
            ),
            label: const Text('✨ Nhập gu riêng...'),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.primaryBrandDark,
            ),
            backgroundColor: colors.bgBrandSubtle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              side: BorderSide(
                color: colors.primaryBrand.withValues(alpha: 0.3),
              ),
            ),
            onPressed: () {
              AiCustomPromptBottomSheet.show(
                context,
                initialPrompt: state?.activePrompt,
                onSubmitted: (prompt) {
                  ref
                      .read(aiRecommendationViewModelProvider.notifier)
                      .filterByPrompt(prompt, chipLabel: 'Tự nhập');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Danh sách thẻ truyện cuộn ngang (Data State)
  Widget _buildDataList(
    BuildContext context,
    AppColors colors,
    List<AiRecommendation> items,
  ) {
    return SizedBox(
      height: 255,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.space3),
        itemBuilder: (context, index) {
          final item = items[index];
          return _AiSeriesCard(
            item: item,
            onTap: () {
              context.push(
                AppPaths.seriesDetail(item.series.id),
                extra: item.series,
              );
            },
          );
        },
      ),
    );
  }

  /// Trạng thái Đang tải (Skeleton Shimmer)
  Widget _buildLoadingState(AppColors colors) {
    return SizedBox(
      height: 255,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.space3),
        itemBuilder: (context, index) => _buildSkeletonCard(colors),
      ),
    );
  }

  Widget _buildSkeletonCard(AppColors colors) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 190,
            width: 140,
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome,
                color: colors.textMuted.withValues(alpha: 0.3),
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 10,
            width: 80,
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  /// Trạng thái Lỗi (Error State)
  Widget _buildErrorState(WidgetRef ref, AppColors colors, Object err) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
      padding: const EdgeInsets.all(AppDimensions.space3),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.warning, size: 20),
          const SizedBox(width: AppDimensions.space2),
          Expanded(
            child: Text(
              'Không thể tải gợi ý AI lúc này. Vui lòng thử lại.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () =>
                ref.read(aiRecommendationViewModelProvider.notifier).refresh(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Trạng thái Rỗng (Empty State)
  Widget _buildEmptyState(WidgetRef ref, AppColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, color: colors.textMuted, size: 32),
            const SizedBox(height: 6),
            Text(
              'Chưa có truyện phù hợp với gu đọc này',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy thử đổi từ khóa hoặc chọn thể loại khác nhé.',
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref
                  .read(aiRecommendationViewModelProvider.notifier)
                  .resetToDefault(),
              child: const Text('Về gợi ý mặc định'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ hiển thị một truyện trong danh sách gợi ý AI
class _AiSeriesCard extends StatelessWidget {
  final AiRecommendation item;
  final VoidCallback onTap;

  const _AiSeriesCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final series = item.series;
    final matchPct = item.matchPercentage;

    return SizedBox(
      width: 140,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa + Huy hiệu độ tương đồng
            Stack(
              children: [
                // Ảnh bìa
                Container(
                  height: 190,
                  width: 140,
                  decoration: BoxDecoration(
                    color: colors.bgSurfaceSubtle,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: colors.borderDefault),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: series.coverImageUrl.isNotEmpty
                      ? Image.network(
                          series.coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPlaceholder(colors),
                        )
                      : _buildPlaceholder(colors),
                ),

                // Huy hiệu phần trăm tương đồng AI
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primaryBrandDark, colors.primaryBrand],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          matchPct > 0 ? '$matchPct%' : 'AI Match',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Tiêu đề truyện
            Text(
              series.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),

            // Đánh giá sao hoặc Tác giả
            Row(
              children: [
                if (series.averageRating > 0) ...[
                  Icon(Icons.star_rounded, size: 14, color: colors.accent),
                  const SizedBox(width: 2),
                  Text(
                    series.averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '•',
                    style: TextStyle(color: colors.textMuted, fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    series.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(AppColors colors) {
    return Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 32,
        color: colors.textMuted.withValues(alpha: 0.4),
      ),
    );
  }
}
