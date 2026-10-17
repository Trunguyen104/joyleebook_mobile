import 'package:flutter/material.dart';
import '../themes/app_dimensions.dart';

/// WIDGET HUY HIỆU / NHÃN (JoyleeBadge)
/// Thành phần giao diện dùng chung để hiển thị các nhãn nhỏ như 'Free', 'NOW', '% read', thể loại...
class JoyleeBadge extends StatelessWidget {
  const JoyleeBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }
}
