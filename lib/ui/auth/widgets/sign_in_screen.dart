import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_text_field.dart';
import '../view_models/sign_in_view_model.dart';
import 'auth_form_widgets.dart';

/// Màn hình Đăng nhập.
/// Đăng nhập xong không cần tự điều hướng: GoRouter thấy đã có phiên
/// sẽ tự đưa người dùng về trang [from] (mặc định là Kho Truyện).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, this.from});

  /// Trang người dùng định vào trước khi bị chuyển sang đăng nhập
  final String? from;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    // Lấy messenger trước khi await vì màn hình có thể đã đóng sau đó
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(signInViewModelProvider.notifier)
        .submit(
          username: _usernameController.text,
          password: _passwordController.text,
        );
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đăng nhập thành công')),
      );
      if (mounted && GoRouter.maybeOf(context) != null) {
        context.go(widget.from ?? AppPaths.series);
      }
    }
  }

  void _handleBack() {
    if (GoRouter.maybeOf(context) != null && context.canPop()) {
      context.pop();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      if (GoRouter.maybeOf(context) != null) {
        context.go(AppPaths.series);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signInViewModelProvider);

    // Lỗi từ máy chủ (sai mật khẩu, mất mạng...) -> SnackBar
    ref.listen(signInViewModelProvider.select((s) => s.errorMessage), (
      _,
      message,
    ) {
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

    final colors = context.colors;

    return AuthScaffold(
      appBarTitle: 'Đăng nhập / Đăng ký',
      title: 'Chào mừng trở lại',
      subtitle: 'Đăng nhập để tiếp tục những trang truyện còn dang dở.',
      onBack: _handleBack,
      // AutofillGroup: cho phép trình quản lý mật khẩu điền sẵn tài khoản
      form: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            JoyleeTextField(
              label: 'Tên đăng nhập hoặc email',
              hintText: 'Nhập tên đăng nhập hoặc email',
              controller: _usernameController,
              errorText: state.usernameError,
              prefixIcon: Icon(Icons.person_outline, color: colors.textMuted),
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
            ),
            const SizedBox(height: AppDimensions.space4),
            JoyleeTextField(
              label: 'Mật khẩu',
              hintText: 'Nhập mật khẩu',
              controller: _passwordController,
              errorText: state.passwordError,
              obscureText: _obscurePassword,
              prefixIcon: Icon(Icons.lock_outline, color: colors.textMuted),
              suffixIcon: PasswordVisibilityToggle(
                obscure: _obscurePassword,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppDimensions.space2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(
                  authPathWithFrom(AppPaths.forgotPassword, widget.from),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: colors.textLink,
                ),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: AppDimensions.space5),
            JoyleeButton(
              label: 'Đăng nhập',
              isLoading: state.isLoading,
              // null khi đang gửi -> nút bị vô hiệu hóa, chống bấm 2 lần
              onPressed: state.isLoading ? null : _submit,
            ),
          ],
        ),
      ),
      footer: AuthSwitchLink(
        question: 'Chưa có tài khoản?',
        actionLabel: 'Đăng ký',
        onPressed: () =>
            context.go(authPathWithFrom(AppPaths.signUp, widget.from)),
      ),
    );
  }
}
