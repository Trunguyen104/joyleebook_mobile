import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';

/// WIDGET NÚT TIẾP TỤC ĐỌC GHIM ĐÁY (ResumeReadingBar)
/// Hiển thị thanh nút nổi (Floating Pill) ở đáy màn hình khi có chương đang đọc dở.
class ResumeReadingBar extends StatelessWidget {
  const ResumeReadingBar({
    super.key,
    required this.title,
    required this.onPressed,
    this.progressPercentage,
  });

  final String title;
  final VoidCallback onPressed;
  final int? progressPercentage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = progressPercentage != null
        ? 'Resume $title ($progressPercentage%)'
        : 'Resume $title';

    return Positioned(
      left: AppDimensions.space4,
      right: AppDimensions.space4,
      bottom: AppDimensions.space4,
      child: SafeArea(
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(
              Icons.play_circle_fill_rounded,
              size: 26,
              color: Colors.white,
            ),
            label: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 4,
              shadowColor: colors.accent.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
