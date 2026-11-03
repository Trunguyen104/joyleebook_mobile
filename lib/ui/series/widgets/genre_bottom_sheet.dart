import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/genre.dart';
import '../../../domain/models/series.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/genre_list_view_model.dart';
import '../view_models/series_list_view_model.dart';

/// MODAL BOTTOM SHEET: Xem toàn bộ thể loại và bộ lọc nâng cao
/// Tuân thủ Design System (bo góc radiusLg, drag handle, Warm Editorial tokens).
class GenreBottomSheet extends ConsumerWidget {
  const GenreBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GenreBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final genresState = ref.watch(genreListViewModelProvider);
    final seriesVm = ref.watch(seriesListViewModelProvider.notifier);
    final selectedGenre = seriesVm.selectedGenre;
    final selectedStatus = seriesVm.selectedStatus;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.bgCanvas,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh gạt (Drag handle)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),

            // Tiêu đề & Nút đóng
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space4,
                vertical: AppDimensions.space2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tất cả Thể loại & Bộ lọc',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Nội dung cuộn
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PHẦN 1: LỌC THEO TRẠNG THÁI TRUYỆN
                    Text(
                      'Trạng thái phát hành',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space2),
                    Wrap(
                      spacing: AppDimensions.space2,
                      runSpacing: AppDimensions.space2,
                      children: [
                        _buildStatusChip(
                          context: context,
                          label: 'Tất cả trạng thái',
                          isSelected: selectedStatus == null,
                          onSelected: () {
                            ref
                                .read(seriesListViewModelProvider.notifier)
                                .filterByStatus(null);
                          },
                          colors: colors,
                        ),
                        _buildStatusChip(
                          context: context,
                          label: SeriesStatus.ongoing.label,
                          isSelected: selectedStatus == SeriesStatus.ongoing,
                          onSelected: () {
                            ref
                                .read(seriesListViewModelProvider.notifier)
                                .filterByStatus(SeriesStatus.ongoing);
                          },
                          colors: colors,
                        ),
                        _buildStatusChip(
                          context: context,
                          label: SeriesStatus.completed.label,
                          isSelected: selectedStatus == SeriesStatus.completed,
                          onSelected: () {
                            ref
                                .read(seriesListViewModelProvider.notifier)
                                .filterByStatus(SeriesStatus.completed);
                          },
                          colors: colors,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.space4),

                    // PHẦN 2: DANH MỤC THỂ LOẠI (VIEW GENRES - BỘ 4 TRẠNG THÁI)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Danh mục Thể loại',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (selectedGenre != null)
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(seriesListViewModelProvider.notifier)
                                  .filterByGenre(null);
                            },
                            child: const Text('Bỏ chọn thể loại'),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space2),

                    genresState.when(
                      loading: () => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.space4),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.primaryBrand,
                            ),
                          ),
                        ),
                      ),
                      error: (err, _) => JoyleeErrorView(
                        message: 'Không thể tải danh sách thể loại.',
                        onRetry: () => ref
                            .read(genreListViewModelProvider.notifier)
                            .refresh(),
                      ),
                      data: (genres) {
                        if (genres.isEmpty) {
                          return JoyleeEmptyState(
                            title: 'Chưa có thể loại nào',
                            message: 'Danh mục thể loại hiện đang được cập nhật.',
                            actionLabel: 'Tải lại',
                            onAction: () => ref
                                .read(genreListViewModelProvider.notifier)
                                .refresh(),
                          );
                        }

                        return _buildGenresGrid(
                          context: context,
                          ref: ref,
                          genres: genres,
                          selectedGenre: selectedGenre,
                          colors: colors,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Nút Thao tác dưới đáy
            Container(
              padding: const EdgeInsets.all(AppDimensions.space4),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border(
                  top: BorderSide(color: colors.borderDefault),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: JoyleeButton(
                      label: 'Xóa bộ lọc',
                      variant: JoyleeButtonVariant.secondary,
                      onPressed: () {
                        ref
                            .read(seriesListViewModelProvider.notifier)
                            .clearFilters();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space3),
                  Expanded(
                    child: JoyleeButton(
                      label: 'Áp dụng',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required AppColors colors,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? colors.primaryBrand : colors.textSecondary,
      ),
      backgroundColor: colors.bgSurface,
      selectedColor: colors.primaryBrand.withValues(alpha: 0.15),
      checkmarkColor: colors.primaryBrand,
      side: BorderSide(
        color: isSelected ? colors.primaryBrand : colors.borderDefault,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
    );
  }

  Widget _buildGenresGrid({
    required BuildContext context,
    required WidgetRef ref,
    required List<Genre> genres,
    required String? selectedGenre,
    required AppColors colors,
  }) {
    return Wrap(
      spacing: AppDimensions.space2,
      runSpacing: AppDimensions.space2,
      children: genres.map((genre) {
        final isSelected = selectedGenre != null &&
            (selectedGenre.toLowerCase() == genre.name.toLowerCase() ||
                genre.name.toLowerCase().contains(selectedGenre.toLowerCase()));

        return FilterChip(
          label: Text(
            genre.seriesCount > 0
                ? '${genre.name} (${genre.seriesCount})'
                : genre.name,
          ),
          selected: isSelected,
          onSelected: (_) {
            ref
                .read(seriesListViewModelProvider.notifier)
                .filterByGenre(genre.name);
          },
          labelStyle: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? colors.primaryBrand : colors.textPrimary,
          ),
          backgroundColor: colors.bgSurface,
          selectedColor: colors.primaryBrand.withValues(alpha: 0.15),
          checkmarkColor: colors.primaryBrand,
          side: BorderSide(
            color: isSelected ? colors.primaryBrand : colors.borderDefault,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        );
      }).toList(),
    );
  }
}
