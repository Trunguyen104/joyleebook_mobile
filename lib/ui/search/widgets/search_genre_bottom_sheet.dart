import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/genre.dart';
import '../../../domain/models/series.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../../series/view_models/genre_list_view_model.dart';
import '../view_models/search_view_model.dart';

/// MODAL BOTTOM SHEET: Xem toàn bộ thể loại và bộ lọc nâng cao trên trang Tìm kiếm
/// Tuân thủ Design System (bo góc radiusLg, drag handle, Warm Editorial tokens).
class SearchGenreBottomSheet extends ConsumerWidget {
  const SearchGenreBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SearchGenreBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final genresState = ref.watch(genreListViewModelProvider);
    final searchVm = ref.watch(searchViewModelProvider.notifier);
    final selectedGenre = searchVm.selectedGenre;
    final selectedStatus = searchVm.selectedStatus;

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
                                .read(searchViewModelProvider.notifier)
                                .filterByStatus(null);
                          },
                          colors: colors,
                        ),
                        _buildStatusChip(
                          context: context,
                          label: 'Đang tiến hành',
                          isSelected: selectedStatus == SeriesStatus.ongoing,
                          onSelected: () {
                            ref
                                .read(searchViewModelProvider.notifier)
                                .filterByStatus(SeriesStatus.ongoing);
                          },
                          colors: colors,
                        ),
                        _buildStatusChip(
                          context: context,
                          label: 'Hoàn thành',
                          isSelected: selectedStatus == SeriesStatus.completed,
                          onSelected: () {
                            ref
                                .read(searchViewModelProvider.notifier)
                                .filterByStatus(SeriesStatus.completed);
                          },
                          colors: colors,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.space4),

                    // PHẦN 2: LỌC THEO THỂ LOẠI
                    Row(
                      children: [
                        Text(
                          'Danh mục Thể loại',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (selectedGenre != null)
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(searchViewModelProvider.notifier)
                                  .filterByGenre(null);
                            },
                            child: Text(
                              'Bỏ chọn',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.primaryBrand,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space2),

                    // Xử lý 3 trạng thái bất đồng bộ của Thể loại
                    genresState.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppDimensions.space4),
                          child: CircularProgressIndicator(),
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
                            .read(searchViewModelProvider.notifier)
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
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: colors.primaryBrand,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colors.textOnBrand : colors.textPrimary,
      ),
      backgroundColor: colors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        side: BorderSide(
          color: isSelected ? colors.primaryBrand : colors.borderDefault,
        ),
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

        return _buildGenreChip(
          genreName: genre.name,
          count: genre.seriesCount,
          isSelected: isSelected,
          onTap: () {
            ref
                .read(searchViewModelProvider.notifier)
                .filterByGenre(isSelected ? null : genre.name);
          },
          colors: colors,
        );
      }).toList(),
    );
  }

  Widget _buildGenreChip({
    required String genreName,
    required int? count,
    required bool isSelected,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    final hasCount = count != null && count > 0;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(genreName),
          if (hasCount) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.bgCanvas.withValues(alpha: 0.3)
                    : colors.bgBrandSubtle,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colors.textOnBrand : colors.primaryBrand,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colors.primaryBrand,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colors.textOnBrand : colors.textPrimary,
      ),
      backgroundColor: colors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        side: BorderSide(
          color: isSelected ? colors.primaryBrand : colors.borderDefault,
        ),
      ),
    );
  }
}
