# JoyleeBook Mobile — Hướng dẫn Thiết lập Theme & Shared Components (Design System)

Tài liệu này hướng dẫn cách cấu hình giao diện Flutter Mobile đồng bộ **1:1** với Web (`frontend/JoyleeBook.Web`), đóng vai trò như `global.css` và hệ thống token trong Flutter, cùng với quy tắc phân bổ và triển khai các **Shared Widgets** dùng chung tại `lib/ui/core/`.

---

## 1. Triết lý thiết kế: Warm Editorial

Giống như Web Blazor, ứng dụng Mobile theo đuổi phong cách **Warm Editorial** — ấm áp, thư thái, tối ưu cho việc đọc truyện lâu mà không mỏi mắt:
- **Plum (Mận)**: Màu nhận diện thương hiệu và hành động chính (`Primary`).
- **Amber (Hổ phách)**: Điểm nhấn, huy hiệu, trạng thái (`Secondary/Accent`).
- **Paper & Ink**: Tông màu giấy ngà và mực in thay thế hoàn toàn cho nền trắng tinh và đen thuần để giảm độ chói lóa.

---

## 2. Bảng ánh xạ Token giữa Web và Flutter Mobile

| Vai trò thiết kế | CSS Token trên Web (`tokens.css`) | Flutter Token (`AppColors`) | Mã màu Light | Mã màu Dark |
| :--- | :--- | :--- | :---: | :---: |
| **Nền ứng dụng (Canvas)** | `--jl-color-bg-canvas` | `bgCanvas` | `#FFFCF7` | `#1D1917` |
| **Bề mặt thẻ/ô nhập (Surface)** | `--jl-color-bg-surface` | `bgSurface` | `#FFFFFF` | `#2A2421` |
| **Bề mặt phụ (Subtle Surface)** | `--jl-color-bg-surface-subtle` | `bgSurfaceSubtle` | `#FBF5EC` | `#3A312D` |
| **Nền tô nhẹ màu thương hiệu (avatar, badge)** | `--jl-color-bg-brand-subtle` | `bgBrandSubtle` | `#F8F2FA` | `#34183F` |
| **Màu thương hiệu chính** | `--jl-color-bg-brand` | `primaryBrand` | `#773B8E` | `#914FA7` |
| **Màu thương hiệu khi nhấn** | `--jl-color-bg-brand-hover` | `primaryBrandDark` | `#5F2E72` | `#773B8E` |
| **Màu điểm nhấn (Accent/Amber)** | `--jl-color-bg-accent` | `accent` | `#D58522` | `#F0BD5A` |
| **Chữ tiêu đề / Nội dung chính** | `--jl-color-text-primary` | `textPrimary` | `#1D1917` | `#FFFCF7` |
| **Chữ phụ / Metadata** | `--jl-color-text-secondary` | `textSecondary` | `#574A43` | `#C9BDB3` |
| **Chữ chú thích / Mốc thời gian** | `--jl-color-text-muted` | `textMuted` | `#6D5E56` | `#AA9A8F` |
| **Chữ bị vô hiệu / Placeholder** | `--jl-color-text-disabled` | `textDisabled` | `#8A7A70` | `#8A7A70` |
| **Chữ trên nền thương hiệu** | `--jl-color-text-on-brand` | `textOnBrand` | `#FFFFFF` | `#FFFFFF` |
| **Chữ màu thương hiệu (badge, eyebrow)** | `--jl-color-text-brand` | `textBrand` | `#5F2E72` | `#DFC3E7` |
| **Liên kết / Icon thương hiệu** | `--jl-color-text-link` | `textLink` | `#773B8E` | `#DFC3E7` |
| **Đường viền mặc định** | `--jl-color-border-default` | `borderDefault` | `#E2D9D2` | `#574A43` |
| **Đường viền khi focus ô nhập** | `--jl-color-border-focus` | `borderFocus` | `#914FA7` | `#F0BD5A` |
| **Trạng thái Thành công (Success)** | `--jl-color-text-success` | `success` | `#2D7B57` | `#82C9A6` |
| **Trạng thái Cảnh báo (Warning)** | `--jl-color-text-warning` | `warning` | `#8F4E13` | `#F8D88F` |
| **Trạng thái Nguy hiểm/Lỗi (Danger)**| `--jl-color-text-danger` | `danger` | `#B74B43` | `#F0A49D` |

---

## 3. Cài đặt hệ thống Theme trong Flutter

Để đạt được hiệu ứng tương tự `global.css` trên Web (cho phép đổi Light/Dark mode tự động và gọi màu ngữ nghĩa ở mọi nơi), chúng ta triển khai `ThemeExtension` trong Flutter:

### 3.1. File hằng số kích thước `lib/ui/core/themes/app_dimensions.dart`
```dart
abstract final class AppDimensions {
  // Spacing (Base unit 4px)
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0; // Padding chuẩn mobile
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;

  // Border Radius (Đồng bộ LayoutProperties MudBlazor 10px)
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0; // Bo góc thẻ chuẩn
  static const double radiusLg = 16.0;
  static const double radiusFull = 999.0;

  // Touch & Control Sizes
  static const double controlHeight = 44.0; // Chuẩn tối thiểu
  static const double minTouchTarget = 48.0; // Chuẩn Material 3
}
```

### 3.2. File màu ngữ nghĩa `lib/ui/core/themes/app_colors.dart`
```dart
import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgSurfaceSubtle,
    required this.bgBrandSubtle,
    required this.primaryBrand,
    required this.primaryBrandDark,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textOnBrand,
    required this.textBrand,
    required this.textLink,
    required this.borderDefault,
    required this.borderFocus,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSurfaceSubtle;
  final Color bgBrandSubtle;
  final Color primaryBrand;
  final Color primaryBrandDark;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color textOnBrand;
  final Color textBrand;
  final Color textLink;
  final Color borderDefault;
  final Color borderFocus;
  final Color success;
  final Color warning;
  final Color danger;

  // Cấu hình bảng màu Light (Đồng bộ PaletteLight Web Blazor)
  static const light = AppColors(
    bgCanvas: Color(0xFFFFFCF7),
    bgSurface: Color(0xFFFFFFFF),
    bgSurfaceSubtle: Color(0xFFFBF5EC),
    bgBrandSubtle: Color(0xFFF8F2FA),
    primaryBrand: Color(0xFF773B8E),
    primaryBrandDark: Color(0xFF5F2E72),
    accent: Color(0xFFD58522),
    textPrimary: Color(0xFF1D1917),
    textSecondary: Color(0xFF574A43),
    textMuted: Color(0xFF6D5E56),
    textDisabled: Color(0xFF8A7A70),
    textOnBrand: Color(0xFFFFFFFF),
    textBrand: Color(0xFF5F2E72),
    textLink: Color(0xFF773B8E),
    borderDefault: Color(0xFFE2D9D2),
    borderFocus: Color(0xFF914FA7),
    success: Color(0xFF2D7B57),
    warning: Color(0xFF8F4E13),
    danger: Color(0xFFB74B43),
  );

  // Cấu hình bảng màu Dark (Đồng bộ PaletteDark Web Blazor)
  static const dark = AppColors(
    bgCanvas: Color(0xFF1D1917),
    bgSurface: Color(0xFF2A2421),
    bgSurfaceSubtle: Color(0xFF3A312D),
    bgBrandSubtle: Color(0xFF34183F),
    primaryBrand: Color(0xFF914FA7),
    primaryBrandDark: Color(0xFF773B8E),
    accent: Color(0xFFF0BD5A),
    textPrimary: Color(0xFFFFFCF7),
    textSecondary: Color(0xFFC9BDB3),
    textMuted: Color(0xFFAA9A8F),
    textDisabled: Color(0xFF8A7A70),
    textOnBrand: Color(0xFFFFFFFF),
    textBrand: Color(0xFFDFC3E7),
    textLink: Color(0xFFDFC3E7),
    borderDefault: Color(0xFF574A43),
    borderFocus: Color(0xFFF0BD5A),
    success: Color(0xFF82C9A6),
    warning: Color(0xFFF8D88F),
    danger: Color(0xFFF0A49D),
  );

  @override
  AppColors copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgSurfaceSubtle,
    Color? bgBrandSubtle,
    Color? primaryBrand,
    Color? primaryBrandDark,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
    Color? textOnBrand,
    Color? textBrand,
    Color? textLink,
    Color? borderDefault,
    Color? borderFocus,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppColors(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgSurfaceSubtle: bgSurfaceSubtle ?? this.bgSurfaceSubtle,
      bgBrandSubtle: bgBrandSubtle ?? this.bgBrandSubtle,
      primaryBrand: primaryBrand ?? this.primaryBrand,
      primaryBrandDark: primaryBrandDark ?? this.primaryBrandDark,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textDisabled: textDisabled ?? this.textDisabled,
      textOnBrand: textOnBrand ?? this.textOnBrand,
      textBrand: textBrand ?? this.textBrand,
      textLink: textLink ?? this.textLink,
      borderDefault: borderDefault ?? this.borderDefault,
      borderFocus: borderFocus ?? this.borderFocus,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSurfaceSubtle: Color.lerp(bgSurfaceSubtle, other.bgSurfaceSubtle, t)!,
      bgBrandSubtle: Color.lerp(bgBrandSubtle, other.bgBrandSubtle, t)!,
      primaryBrand: Color.lerp(primaryBrand, other.primaryBrand, t)!,
      primaryBrandDark: Color.lerp(primaryBrandDark, other.primaryBrandDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textOnBrand: Color.lerp(textOnBrand, other.textOnBrand, t)!,
      textBrand: Color.lerp(textBrand, other.textBrand, t)!,
      textLink: Color.lerp(textLink, other.textLink, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

// Extension helper để gọi trực tiếp context.colors
extension AppColorsBuildContextX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
```

### 3.3. File cấu hình ThemeData `lib/ui/core/themes/app_theme.dart`
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

abstract final class AppTheme {
  static ThemeData get light => _createTheme(AppColors.light, Brightness.light);
  static ThemeData get dark => _createTheme(AppColors.dark, Brightness.dark);

  static ThemeData _createTheme(AppColors colors, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.bgCanvas,
      fontFamily: 'Inter',
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primaryBrand,
        onPrimary: colors.textOnBrand,
        secondary: colors.accent,
        onSecondary: colors.textPrimary,
        error: colors.danger,
        onError: colors.textOnBrand,
        surface: colors.bgSurface,
        onSurface: colors.textPrimary,
      ),
      cardTheme: CardTheme(
        color: colors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: BorderSide(color: colors.borderDefault, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgCanvas,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      extensions: [colors],
    );
  }
}
```

---

## 4. Nguyên tắc Tổ chức Shared Components (`lib/ui/core/widgets/`)

Thư mục `lib/ui/core/widgets/` chứa các component dùng chung cho toàn bộ app. Việc đưa một widget vào đây phải tuân thủ nghiêm ngặt các nguyên tắc sau:

### 4.1. Quy tắc quyết định: Khi nào CẦN tạo trong `ui/core/widgets/`?

Chỉ tạo widget trong `core/widgets/` khi thỏa mãn **ít nhất 1 trong 3 điều kiện**:
1. **Quy tắc 2 màn hình (Reuse Rule)**: Widget đó được sử dụng ở **từ 2 màn hình hoặc 2 tính năng khác nhau trở lên** (Ví dụ: `JoyleeButton` dùng ở Auth, Series, Profile...).
2. **Định hình bộ nhận diện thương hiệu (Brand Foundation)**: Widget mang phong cách riêng của JoyleeBook (Ví dụ: Ô nhập liệu có viền Plum bo tròn, thẻ truyện có tỷ lệ bìa sách 2:3).
3. **Thành phần hạ tầng hệ thống (System States)**: Các trạng thái bắt buộc của app như Loading, Error, Empty, Confirm Dialog.

### 4.2. Quy tắc cấm: Khi nào KHÔNG ĐƯỢC tạo trong `ui/core/widgets/`?

- ❌ **Widget chỉ phục vụ 1 màn hình duy nhất**: Ví dụ `SignInBanner`, `SeriesDetailHeroCover`, `ChapterReadingToolbar` -> **Bắt buộc** đặt trong thư mục tính năng tương ứng: `lib/ui/auth/widgets/` hoặc `lib/ui/series/widgets/`.
- ❌ **Widget chứa logic nghiệp vụ cụ thể (Business/Domain Leaks)**: Core widget tuyệt đối không được phụ thuộc vào Model nghiệp vụ (ví dụ: không nhận đối tượng `Series` hay `User`). Chỉ nhận primitive types (`String`, `bool`, `VoidCallback`, `Widget`).
- ❌ **Tránh bọc (wrapper) vô bổ**: Không tạo các widget bọc lại những component cơ bản của Flutter nếu không bổ sung logic hay style mới (ví dụ: Không tạo `AppPadding`, `AppSizedBox`, `AppRow`...).

---

## 5. Danh mục và Mã nguồn các Shared Widgets thiết yếu

Dưới đây là 6 Shared Widgets chuẩn mực cần có trong dự án:

### 5.1. Nút bấm chuẩn thương hiệu (`lib/ui/core/widgets/joylee_button.dart`)
Tích hợp sẵn trạng thái Loading (tự đổi sang spinner và vô hiệu hóa click chống spam):

```dart
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
```

### 5.2. Ô nhập liệu chuẩn (`lib/ui/core/widgets/joylee_text_field.dart`)
Tự động viền màu Plum khi focus, viền đỏ khi có lỗi:

```dart
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_dimensions.dart';

class JoyleeTextField extends StatelessWidget {
  const JoyleeTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.space1),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: colors.textDisabled, fontSize: 14),
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colors.bgSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space4,
              vertical: AppDimensions.space3,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(color: colors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(color: colors.borderFocus, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(color: colors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(color: colors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
```

### 5.3. Giao diện danh sách rỗng (`lib/ui/core/widgets/joylee_empty_state.dart`)
```dart
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_dimensions.dart';
import 'joylee_button.dart';

class JoyleeEmptyState extends StatelessWidget {
  const JoyleeEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.iconData = Icons.auto_stories_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData iconData;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 64, color: colors.textDisabled),
            const SizedBox(height: AppDimensions.space4),
            Text(
              title,
              textAlign: TextAlign.center,
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
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.space6),
              JoyleeButton(
                label: actionLabel!,
                onPressed: onAction,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 5.4. Giao diện báo lỗi có nút Thử lại (`lib/ui/core/widgets/joylee_error_view.dart`)
```dart
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_dimensions.dart';
import 'joylee_button.dart';

class JoyleeErrorView extends StatelessWidget {
  const JoyleeErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

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
              'Có lỗi xảy ra',
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
```

### 5.5. Hộp thoại xác nhận hành động nguy hiểm (`lib/ui/core/widgets/joylee_confirm_dialog.dart`)
```dart
import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../themes/app_dimensions.dart';

class JoyleeConfirmDialog extends StatelessWidget {
  const JoyleeConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel = 'Xác nhận',
    this.cancelLabel = 'Hủy',
    this.isDanger = false,
  });

  final String title;
  final String content;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Xác nhận',
    String cancelLabel = 'Hủy',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => JoyleeConfirmDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      backgroundColor: colors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
      content: Text(
        content,
        style: TextStyle(fontSize: 14, color: colors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: isDanger ? colors.danger : colors.primaryBrand,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
```

---

### 5.6. Avatar (`lib/ui/core/widgets/joylee_avatar.dart`)
Theo Design System §5.5: 5 cỡ 24/32/40/64/96, không có ảnh hoặc ảnh lỗi thì hiện chữ cái đầu (`text/brand`) trên nền `bg/brand-subtle`. Là brand primitive nên đặt trong `core/` dù hiện mới có màn Hồ sơ dùng; chỉ nhận `String`, không nhận `UserProfile`.

```dart
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
```

---

## 6. Cách sử dụng trong Màn hình thực tế

Ví dụ cách một màn hình (`ui/series/widgets/series_list_screen.dart`) phối hợp các Token và Shared Widgets:

```dart
class SeriesListScreen extends ConsumerWidget {
  const SeriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesState = ref.watch(seriesListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho Truyện JoyleeBook'),
      ),
      body: seriesState.when(
        // 1. Loading State
        loading: () => const Center(child: CircularProgressIndicator()),
        
        // 2. Error State (Có nút Retry)
        error: (err, stack) => JoyleeErrorView(
          message: err.toString(),
          onRetry: () => ref.read(seriesListViewModelProvider.notifier).refresh(),
        ),
        
        // 3. Data hoặc Empty State
        data: (seriesList) {
          if (seriesList.isEmpty) {
            return JoyleeEmptyState(
              title: 'Chưa có truyện nào',
              message: 'Hãy quay lại sau hoặc thử làm mới danh sách.',
              onAction: () => ref.read(seriesListViewModelProvider.notifier).refresh(),
              actionLabel: 'Làm mới',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(seriesListViewModelProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.space4),
              itemCount: seriesList.length,
              itemBuilder: (context, index) {
                final item = seriesList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppDimensions.space3),
                  child: ListTile(
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Tác giả ID: ${item.authorId}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/series/${item.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```
