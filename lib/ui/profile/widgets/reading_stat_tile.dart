import 'package:flutter/material.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_colors.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_dimensions.dart';

/// Ô thống kê (Stat Card): icon trong nền brand-subtle + con số lớn + nhãn
class ReadingStatTile extends StatelessWidget {
  const ReadingStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
  });

  final IconData icon;
  final String value;
  final String label;

  /// Đơn vị nhỏ đứng sau con số, ví dụ "ngày"
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors; // theme darkmode lightmode
    final textTheme = Theme.of(context).textTheme;

    // Trình đọc màn hình đọc gọn một câu: "Chuỗi dài nhất: 7 ngày"
    return Semantics(
      container: true,
      label: '$label: $value${unit == null ? '' : ' $unit'}',
      excludeSemantics: true,
      child: Card(
        // Card lấy viền borderDefault, elevation 0 từ AppTheme
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.bgBrandSubtle,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(icon, size: 20, color: colors.textLink),
              ),
              const SizedBox(height: AppDimensions.space3),
              Text.rich(
                TextSpan(
                  text: value,
                  children: [
                    if (unit != null)
                      TextSpan(
                        text: ' $unit',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.space1),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis, // nhãn dài thì thành "..."
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
