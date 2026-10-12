import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_dimensions.dart';

enum JoyleeButtonVariant { primary, secondary, danger, ghost }

class JoyleeButton extends StatelessWidget {
  const JoyleeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = JoyleeButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final JoyleeButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEnabled = onPressed != null && !isLoading;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case JoyleeButtonVariant.primary:
        bg = colors.primaryBrand;
        fg = colors.textOnBrand;
      case JoyleeButtonVariant.secondary:
        bg = colors.bgSurfaceSubtle;
        fg = colors.textPrimary;
        border = BorderSide(color: colors.borderDefault);
      case JoyleeButtonVariant.danger:
        bg = colors.danger;
        fg = colors.textOnBrand;
      case JoyleeButtonVariant.ghost:
        bg = Colors.transparent;
        fg = colors.primaryBrand;
    }

    final childContent = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: AppDimensions.space2)],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? fg : colors.textDisabled,
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: AppDimensions.controlHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
        onPressed: isEnabled ? onPressed : null,
        child: childContent,
      ),
    );
  }
}
