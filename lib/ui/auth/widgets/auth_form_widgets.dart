import 'package:flutter/material.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../view_models/auth_validators.dart';

/// Các widget dùng chung cho màn Đăng nhập và Đăng ký

/// Khung chung của 2 màn xác thực:
/// dải màu plum nhạt ở đầu trang -> logo -> tiêu đề -> thẻ form -> dòng chuyển màn.
/// Nội dung giới hạn 440px để form không bị kéo giãn trên tablet.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
    required this.onSkip,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;

  /// Nút "Để sau": quay lại Kho Truyện mà không đăng nhập
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.bgBrandSubtle, colors.bgCanvas],
            stops: const [0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.space2),
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textLink,
                    ),
                    child: const Text('Để sau'),
                  ),
                ),
              ),
              // Center + ScrollView: form nằm giữa màn hình khi đủ chỗ,
              // và cuộn được khi bàn phím bật lên
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.space6,
                      0,
                      AppDimensions.space6,
                      AppDimensions.space8,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _BrandMark(),
                            const SizedBox(height: AppDimensions.space8),
                            Text(
                              title,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space2),
                            Text(
                              subtitle,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space6),
                            _FormCard(child: form),
                            const SizedBox(height: AppDimensions.space5),
                            footer,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo: ô vuông bo góc màu brand có biểu tượng sách + wordmark "Joyleebook."
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Joyleebook',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryBrand,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: colors.textOnBrand,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDimensions.space3),
          // Wordmark: chữ đậm, giãn chữ âm, dấu chấm màu brand (theo Design-System §2)
          Flexible(
            child: Text.rich(
              TextSpan(
                text: 'Joyleebook',
                children: [
                  TextSpan(
                    text: '.',
                    style: TextStyle(color: colors.primaryBrand),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.1,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ "giấy" chứa form: nền surface, viền mảnh, không đổ bóng
class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space5),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: child,
    );
  }
}

/// Dòng "Chưa có tài khoản? Đăng ký" ở cuối trang
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onPressed,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: TextStyle(color: colors.textSecondary)),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: colors.textLink),
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Nút con mắt để ẩn/hiện mật khẩu
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.obscure,
    required this.onPressed,
  });

  final bool obscure;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: onPressed,
    );
  }
}

/// Checklist quy tắc mật khẩu, tự đánh dấu khi người dùng gõ đạt từng điều kiện
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = [
      ('Từ 8 ký tự trở lên', passwordHasMinLength(password)),
      ('Có ít nhất 1 chữ cái', passwordHasLetter(password)),
      ('Có ít nhất 1 chữ số', passwordHasDigit(password)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppDimensions.space1,
      children: [
        for (final (label, isMet) in rules)
          _RequirementRow(label: label, isMet: isMet),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: '$label: ${isMet ? 'đã đạt' : 'chưa đạt'}',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: isMet ? colors.success : colors.textMuted,
          ),
          const SizedBox(width: AppDimensions.space2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? colors.success : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Giữ tham số ?from= khi chuyển qua lại giữa Đăng nhập và Đăng ký
String authPathWithFrom(String path, String? from) => Uri(
  path: path,
  queryParameters: from == null ? null : {'from': from},
).toString();
