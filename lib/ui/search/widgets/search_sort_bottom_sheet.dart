import 'package:flutter/material.dart';

import '../../../domain/models/search_sort_option.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';

extension SearchSortOptionPresentation on SearchSortOption {
  IconData get icon => switch (this) {
    SearchSortOption.relevance => Icons.auto_awesome,
    SearchSortOption.newest => Icons.update_rounded,
    SearchSortOption.mostRead => Icons.local_fire_department_rounded,
    SearchSortOption.topRated => Icons.star_rounded,
  };
}

/// BOTTOM SHEET - Chọn tiêu chí sắp xếp cho kết quả tìm kiếm
class SearchSortBottomSheet extends StatelessWidget {
  final SearchSortOption currentOption;
  final ValueChanged<SearchSortOption> onOptionSelected;

  const SearchSortBottomSheet({
    super.key,
    required this.currentOption,
    required this.onOptionSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required SearchSortOption currentOption,
    required ValueChanged<SearchSortOption> onOptionSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchSortBottomSheet(
        currentOption: currentOption,
        onOptionSelected: (opt) {
          Navigator.of(ctx).pop();
          onOptionSelected(opt);
        },
      ),
    );
  }

  static const Map<SearchSortOption, String> _descriptions = {
    SearchSortOption.relevance: 'Theo độ khớp từ khóa và mức độ liên quan',
    SearchSortOption.newest: 'Tác phẩm mới nhất hoặc đang được cập nhật',
    SearchSortOption.mostRead:
        'Tác phẩm có nhiều lượt đọc và quy mô chương lớn',
    SearchSortOption.topRated:
        'Điểm số đánh giá trung bình từ độc giả cao nhất',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space4,
        AppDimensions.space3,
        AppDimensions.space4,
        AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh kéo handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimensions.space3),
                decoration: BoxDecoration(
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Tiêu đề
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sắp xếp danh sách',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space2),

            // Danh sách các tùy chọn
            ...SearchSortOption.values.map((option) {
              final isSelected = option == currentOption;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSelected ? colors.bgBrandSubtle : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: isSelected
                        ? colors.primaryBrand.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  leading: Icon(
                    option.icon,
                    color: isSelected
                        ? colors.primaryBrand
                        : colors.textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? colors.primaryBrand
                          : colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    _descriptions[option] ?? '',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: colors.primaryBrand,
                          size: 20,
                        )
                      : null,
                  onTap: () => onOptionSelected(option),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
