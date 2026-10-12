import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_dimensions.dart';
import 'joylee_button.dart';

class JoyleeErrorView extends StatelessWidget {
  const JoyleeErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Có lỗi xảy ra',
  });

  final String message;
  final VoidCallback? onRetry;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: colors.danger),
            const SizedBox(height: AppDimensions.space4),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.space6),
              JoyleeButton(
                label: 'Thử lại',
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: onRetry,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
