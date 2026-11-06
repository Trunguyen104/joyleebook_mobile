import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_text_field.dart';
import '../view_models/change_password_view_model.dart';
import 'auth_form_widgets.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _obscure = [true, true, true];

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(changePasswordViewModelProvider.notifier)
        .submit(
          currentPassword: _current.text,
          newPassword: _password.text,
          confirmNewPassword: _confirm.text,
        );
    if (!success) return;
    if (mounted) {
      _current.clear();
      _password.clear();
      _confirm.clear();
    }
    if (messenger.mounted) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Đổi mật khẩu thành công. Vui lòng đăng nhập lại bằng mật khẩu mới.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordViewModelProvider);
    ref.listen(changePasswordViewModelProvider.select((s) => s.errorMessage), (
      _,
      message,
    ) {
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });
    final controllers = [_current, _password, _confirm];
    final labels = [
      'Mật khẩu hiện tại',
      'Mật khẩu mới',
      'Xác nhận mật khẩu mới',
    ];
    final errors = [
      state.currentPasswordError,
      state.passwordError,
      state.confirmPasswordError,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space6),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Mật khẩu mới cần có 8–128 ký tự, bao gồm chữ cái và chữ số. Sau khi đổi mật khẩu, bạn sẽ cần đăng nhập lại.',
                    ),
                    const SizedBox(height: AppDimensions.space6),
                    for (var i = 0; i < 3; i++) ...[
                      JoyleeTextField(
                        label: labels[i],
                        controller: controllers[i],
                        errorText: errors[i],
                        obscureText: _obscure[i],
                        autofillHints: [
                          i == 0
                              ? AutofillHints.password
                              : AutofillHints.newPassword,
                        ],
                        textInputAction: i == 2
                            ? TextInputAction.done
                            : TextInputAction.next,
                        onSubmitted: i == 2 ? (_) => _submit() : null,
                        suffixIcon: PasswordVisibilityToggle(
                          obscure: _obscure[i],
                          onPressed: () =>
                              setState(() => _obscure[i] = !_obscure[i]),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space4),
                    ],
                    const SizedBox(height: AppDimensions.space2),
                    JoyleeButton(
                      label: 'Đổi mật khẩu',
                      isLoading: state.isLoading,
                      onPressed: state.isLoading || state.isSuccess
                          ? null
                          : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
