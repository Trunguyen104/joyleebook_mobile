import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_text_field.dart';
import '../view_models/forgot_password_view_model.dart';
import 'auth_form_widgets.dart';

/// Màn hình Quên mật khẩu.
/// Người dùng nhập email để nhận liên kết khôi phục mật khẩu.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(forgotPasswordViewModelProvider.notifier)
        .submit(email: _emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordViewModelProvider);

    // Lắng nghe lỗi mạng / lỗi máy chủ để hiện SnackBar
    ref.listen(forgotPasswordViewModelProvider.select((s) => s.errorMessage), (
      _,
      message,
    ) {
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    if (state.isSuccess) {
      return AuthScaffold(
        title: 'Đã gửi liên kết đặt lại',
        subtitle: 'Vui lòng kiểm tra hộp thư email của bạn.',
        onSkip: () => context.go(AppPaths.series),
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.bgBrandSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: colors.primaryBrand,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space5),
            Text(
              'Nếu email ${state.submittedEmail ?? ''} tồn tại trong hệ thống, chúng tôi đã gửi liên kết đặt lại mật khẩu.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              'Vui lòng kiểm tra hộp thư đến (bao gồm cả thư mục Spam/Rác).',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space6),
            JoyleeButton(
              label: 'Quay lại Đăng nhập',
              onPressed: () => context.go(
                authPathWithFrom(AppPaths.signIn, widget.from),
              ),
            ),
            const SizedBox(height: AppDimensions.space3),
            Center(
              child: TextButton(
                onPressed: () {
                  _emailController.clear();
                  ref.read(forgotPasswordViewModelProvider.notifier).reset();
                },
                style: TextButton.styleFrom(
                  foregroundColor: colors.textLink,
                ),
                child: const Text('Thử địa chỉ email khác'),
              ),
            ),
          ],
        ),
        footer: AuthSwitchLink(
          question: 'Đã nhớ mật khẩu?',
          actionLabel: 'Đăng nhập',
          onPressed: () => context.go(
            authPathWithFrom(AppPaths.signIn, widget.from),
          ),
        ),
      );
    }

    return AuthScaffold(
      title: 'Quên mật khẩu?',
      subtitle:
          'Nhập địa chỉ email liên kết với tài khoản của bạn để nhận liên kết đặt lại mật khẩu.',
      onSkip: () => context.go(AppPaths.series),
      form: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JoyleeTextField(
              label: 'Email',
              controller: _emailController,
              errorText: state.emailError,
              prefixIcon: Icon(Icons.email_outlined, color: colors.textMuted),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppDimensions.space6),
            JoyleeButton(
              label: 'Gửi liên kết đặt lại',
              isLoading: state.isLoading,
              onPressed: state.isLoading ? null : _submit,
            ),
          ],
        ),
      ),
      footer: AuthSwitchLink(
        question: 'Đã nhớ mật khẩu?',
        actionLabel: 'Đăng nhập',
        onPressed: () => context.go(
          authPathWithFrom(AppPaths.signIn, widget.from),
        ),
      ),
    );
  }
}
