import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';

/// WIDGET - Hiển thị Từ khóa tìm kiếm gần đây & Xu hướng thịnh hành
class SearchRecentKeywords extends StatelessWidget {
  final List<String> recentSearches;
  final ValueChanged<String> onKeywordSelected;
  final ValueChanged<String> onKeywordDeleted;
  final VoidCallback onClearAll;

  const SearchRecentKeywords({
    super.key,
    required this.recentSearches,
    required this.onKeywordSelected,
    required this.onKeywordDeleted,
    required this.onClearAll,
  });

  static const List<String> _trendingKeywords = [
    'Tu tiên',
    'Kỳ ảo',
    'Ngôn tình',
    'Hành động',
    'Trinh thám',
    'Hài hước',
    'Trọng sinh',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space3,
      ),
      children: [
        // 1. KHỐI TÌM KIẾM GẦN ĐÂY
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: colors.primaryBrand,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tìm kiếm gần đây',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Xóa tất cả',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space2),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recentSearches.map((keyword) {
              return InputChip(
                avatar: Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
                label: Text(
                  keyword,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                ),
                backgroundColor: colors.bgSurfaceSubtle,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  side: BorderSide(color: colors.borderDefault),
                ),
                deleteIcon: Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: colors.textSecondary,
                ),
                onDeleted: () => onKeywordDeleted(keyword),
                onPressed: () => onKeywordSelected(keyword),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.space4),
        ],

        // 2. KHỐI XU HƯỚNG TÌM KIẾM
        Row(
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: colors.accent,
            ),
            const SizedBox(width: 6),
            Text(
              'Từ khóa thịnh hành',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space2),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingKeywords.map((keyword) {
            return ActionChip(
              label: Text(
                keyword,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              backgroundColor: colors.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                side: BorderSide(color: colors.borderDefault),
              ),
              onPressed: () => onKeywordSelected(keyword),
            );
          }).toList(),
        ),
      ],
    );
  }
}
