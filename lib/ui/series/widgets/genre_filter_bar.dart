import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../view_models/genre_list_view_model.dart';
import '../view_models/series_list_view_model.dart';
import 'genre_bottom_sheet.dart';

/// THANH CUỘN NHANH THỂ LOẠI (Horizontal Genre Filter Bar)
/// Cung cấp trải nghiệm chọn nhanh thể loại truyện ngay trên trang tra cứu.
class GenreFilterBar extends ConsumerWidget {
  const GenreFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final genresState = ref.watch(genreListViewModelProvider);
    final selectedGenre = ref.watch(
      seriesListViewModelProvider.select((vm) =>
          ref.read(seriesListViewModelProvider.notifier).selectedGenre),
    );
    final selectedStatus = ref.watch(
      seriesListViewModelProvider.select((vm) =>
          ref.read(seriesListViewModelProvider.notifier).selectedStatus),
    );

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
        children: [
          // Nút mở Modal Bộ lọc nâng cao & Xem tất cả thể loại
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space2),
            child: ActionChip(
              avatar: Icon(
                Icons.tune_rounded,
                size: 16,
                color: (selectedGenre != null || selectedStatus != null)
                    ? colors.primaryBrand
                    : colors.textSecondary,
              ),
              label: Text(
                selectedStatus != null
                    ? 'Lọc (${selectedStatus.label})'
                    : 'Bộ lọc',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: (selectedGenre != null || selectedStatus != null)
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: (selectedGenre != null || selectedStatus != null)
                      ? colors.primaryBrand
                      : colors.textSecondary,
                ),
              ),
              backgroundColor:
                  (selectedGenre != null || selectedStatus != null)
                      ? colors.primaryBrand.withValues(alpha: 0.12)
                      : colors.bgSurface,
              side: BorderSide(
                color: (selectedGenre != null || selectedStatus != null)
                    ? colors.primaryBrand
                    : colors.borderDefault,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              onPressed: () => GenreBottomSheet.show(context),
            ),
          ),

          // Chip "Tất cả"
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space2),
            child: ChoiceChip(
              label: const Text('Tất cả'),
              selected: selectedGenre == null,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(seriesListViewModelProvider.notifier)
                      .filterByGenre(null);
                }
              },
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight:
                    selectedGenre == null ? FontWeight.bold : FontWeight.w500,
                color: selectedGenre == null
                    ? colors.primaryBrand
                    : colors.textSecondary,
              ),
              backgroundColor: colors.bgSurface,
              selectedColor: colors.primaryBrand.withValues(alpha: 0.15),
              showCheckmark: false,
              side: BorderSide(
                color: selectedGenre == null
                    ? colors.primaryBrand
                    : colors.borderDefault,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),

          // Danh sách thể loại động từ API
          ...genresState.when(
            loading: () => List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(right: AppDimensions.space2),
                child: Chip(
                  label: const Text('...'),
                  backgroundColor: colors.bgSurfaceSubtle,
                  side: BorderSide(color: colors.borderDefault),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ),
            ),
            error: (_, _) => const [],
            data: (genres) => genres.map((genre) {
              final isSelected = selectedGenre != null &&
                  (selectedGenre.toLowerCase() == genre.name.toLowerCase() ||
                      genre.name
                          .toLowerCase()
                          .contains(selectedGenre.toLowerCase()));

              return Padding(
                padding: const EdgeInsets.only(right: AppDimensions.space2),
                child: ChoiceChip(
                  label: Text(genre.name),
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
                  showCheckmark: false,
                  side: BorderSide(
                    color: isSelected ? colors.primaryBrand : colors.borderDefault,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
