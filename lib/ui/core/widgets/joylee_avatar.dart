import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// Các cỡ avatar theo Design System §5.5: 24, 32, 40, 64, 96 px
enum JoyleeAvatarSize {
  xs(24),
  sm(32),
  md(40),
  lg(64),
  xl(96);

  const JoyleeAvatarSize(this.dimension);

  final double dimension;
}

/// Avatar tròn: tải ảnh từ [imageUrl], không có ảnh hoặc ảnh lỗi thì hiện
/// chữ cái đầu [initials] trên nền brand-subtle.
class JoyleeAvatar extends StatelessWidget {
  const JoyleeAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = JoyleeAvatarSize.md,
    this.semanticLabel,
  });

  final String initials;
  final String? imageUrl;
  final JoyleeAvatarSize size;

  /// Nhãn cho trình đọc màn hình, ví dụ "Ảnh đại diện của phuc123"
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimension = size.dimension;
    final url = imageUrl?.trim();

    final fallback = Container(
      width: dimension,
      height: dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.bgBrandSubtle,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: dimension * 0.4,
          fontWeight: FontWeight.w600,
          color: colors.textBrand,
        ),
      ),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: (url == null || url.isEmpty)
          ? fallback
          : ClipOval(
              child: Image.network(
                url,
                width: dimension,
                height: dimension,
                fit: BoxFit.cover,
                // Đang tải hoặc ảnh lỗi (link hỏng, mất mạng) đều hiện chữ cái đầu
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                    (frame == null && !wasSynchronouslyLoaded)
                    ? fallback
                    : child,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            ),
    );
  }
}
