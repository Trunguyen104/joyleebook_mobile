import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_text_field.dart';
import '../view_models/sign_up_view_model.dart';
import 'auth_form_widgets.dart';

/// Màn hình Đăng ký. Đăng ký thành công thì được đăng nhập luôn,
/// GoRouter sẽ tự đưa người dùng ra khỏi màn hình này.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(signUpViewModelProvider.notifier)
        .submit(
          username: _usernameController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công. Chào mừng bạn!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signUpViewModelProvider);

    ref.listen(signUpViewModelProvider.select((s) => s.errorMessage), (
      _,
      message,
    ) {
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

    final toggle = PasswordVisibilityToggle(
      obscure: _obscurePassword,
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );

    final colors = context.colors;

    return AuthScaffold(
      title: 'Tạo tài khoản',
      subtitle: 'Chỉ mất một phút để bắt đầu hành trình đọc của bạn.',
      onSkip: () => context.go(AppPaths.series),
      form: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JoyleeTextField(
              label: 'Tên đăng nhập',
              controller: _usernameController,
              helperText: '3-64 ký tự, gồm chữ, số và dấu . _ -',
              errorText: state.usernameError,
              prefixIcon: Icon(Icons.person_outline, color: colors.textMuted),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
            ),
            const SizedBox(height: AppDimensions.space4),
            JoyleeTextField(
              label: 'Mật khẩu',
              controller: _passwordController,
              errorText: state.passwordError,
              obscureText: _obscurePassword,
              prefixIcon: Icon(Icons.lock_outline, color: colors.textMuted),
              suffixIcon: toggle,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: AppDimensions.space2),
            // Controller là một ValueListenable -> checklist tự vẽ lại khi gõ
            ValueListenableBuilder(
              valueListenable: _passwordController,
              builder: (context, value, _) =>
                  PasswordRequirements(password: value.text),
            ),
            const SizedBox(height: AppDimensions.space4),
            JoyleeTextField(
              label: 'Nhập lại mật khẩu',
              controller: _confirmPasswordController,
              errorText: state.confirmPasswordError,
              obscureText: _obscurePassword,
              prefixIcon: Icon(Icons.lock_outline, color: colors.textMuted),
              suffixIcon: toggle,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppDimensions.space6),
            JoyleeButton(
              label: 'Đăng ký',
              isLoading: state.isLoading,
              onPressed: state.isLoading ? null : _submit,
            ),
          ],
        ),
      ),
      footer: AuthSwitchLink(
        question: 'Đã có tài khoản?',
        actionLabel: 'Đăng nhập',
        onPressed: () =>
            context.go(authPathWithFrom(AppPaths.signIn, widget.from)),
      ),
    );
  }
}
