import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_paths.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_text_field.dart';
import '../view_models/reset_password_view_model.dart';
import 'auth_form_widgets.dart';

/// Nhận email và mã từ liên kết khôi phục hoặc từ người dùng nhập thủ công.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.email = '',
    this.token = '',
    this.from,
  });

  final String email;
  final String token;
  final String? from;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final _email = TextEditingController(text: widget.email);
  late final _token = TextEditingController(text: widget.token);
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final notifier = ref.read(resetPasswordViewModelProvider.notifier);
    final step = ref.read(resetPasswordViewModelProvider).step;
    if (step == ResetPasswordStep.credentials) {
      await notifier.verify(email: _email.text, token: _token.text);
    } else if (step == ResetPasswordStep.password) {
      await notifier.submit(
        password: _password.text,
        confirmPassword: _confirm.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetPasswordViewModelProvider);
    ref.listen(resetPasswordViewModelProvider, (previous, next) {
      if (next.step == ResetPasswordStep.success ||
          (previous?.step == ResetPasswordStep.password &&
              next.step == ResetPasswordStep.credentials)) {
        _password.clear();
        _confirm.clear();
      }
      if (next.step == ResetPasswordStep.success) _token.clear();
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final success = state.step == ResetPasswordStep.success;
    final enteringPassword = state.step == ResetPasswordStep.password;
    return AuthScaffold(
      title: success ? 'Đã đặt lại mật khẩu' : 'Đặt lại mật khẩu',
      subtitle: success
          ? 'Mật khẩu đã được cập nhật. Hãy đăng nhập bằng mật khẩu mới.'
          : enteringPassword
          ? 'Tạo mật khẩu mới từ 8–128 ký tự, có chữ cái và chữ số.'
          : 'Nhập email và mã khôi phục được gửi trong email của bạn.',
      onSkip: () => context.go(AppPaths.series),
      form: success
          ? JoyleeButton(
              label: 'Quay lại Đăng nhập',
              onPressed: () =>
                  context.go(authPathWithFrom(AppPaths.signIn, widget.from)),
            )
          : AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!enteringPassword) ...[
                    JoyleeTextField(
                      label: 'Email',
                      controller: _email,
                      errorText: state.emailError,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    JoyleeTextField(
                      label: 'Mã khôi phục',
                      controller: _token,
                      obscureText: true,
                      helperText: 'Dán mã hoặc toàn bộ liên kết đặt lại mật khẩu trong email.',
                      errorText: state.tokenError,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                  ] else ...[
                    JoyleeTextField(
                      label: 'Mật khẩu mới',
                      controller: _password,
                      obscureText: _obscure,
                      errorText: state.passwordError,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      suffixIcon: PasswordVisibilityToggle(
                        obscure: _obscure,
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    JoyleeTextField(
                      label: 'Xác nhận mật khẩu mới',
                      controller: _confirm,
                      obscureText: _obscure,
                      errorText: state.confirmPasswordError,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.space6),
                  JoyleeButton(
                    label: enteringPassword ? 'Đặt lại mật khẩu' : 'Tiếp tục',
                    isLoading: state.isLoading,
                    onPressed: state.isLoading ? null : _submit,
                  ),
                  const SizedBox(height: AppDimensions.space3),
                  TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () => context.go(
                            authPathWithFrom(
                              AppPaths.forgotPassword,
                              widget.from,
                            ),
                          ),
                    child: const Text('Yêu cầu mã khôi phục mới'),
                  ),
                ],
              ),
            ),
      footer: success
          ? const SizedBox.shrink()
          : AuthSwitchLink(
              question: 'Đã nhớ mật khẩu?',
              actionLabel: 'Đăng nhập',
              onPressed: () =>
                  context.go(authPathWithFrom(AppPaths.signIn, widget.from)),
            ),
    );
  }
}
