import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_exceptions.dart';
import '../../profile/view_models/profile_view_model.dart';
import 'auth_session_view_model.dart';
import 'auth_validators.dart';

@immutable
class SignUpState {
  final bool isLoading;
  final String? usernameError;
  final String? passwordError;
  final String? confirmPasswordError;

  /// Lỗi chung từ máy chủ (mất mạng, gửi quá nhanh...) -> hiện SnackBar
  final String? errorMessage;

  const SignUpState({
    this.isLoading = false,
    this.usernameError,
    this.passwordError,
    this.confirmPasswordError,
    this.errorMessage,
  });
}

final signUpViewModelProvider =
    NotifierProvider.autoDispose<SignUpViewModel, SignUpState>(
      SignUpViewModel.new,
    );

class SignUpViewModel extends Notifier<SignUpState> {
  @override
  SignUpState build() => const SignUpState();

  /// Trả về true khi đăng ký (và tự đăng nhập) thành công
  Future<bool> submit({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    if (state.isLoading) return false;

    final usernameError = validateUsername(username);
    final passwordError = validatePassword(password);
    final confirmPasswordError = validateConfirmPassword(
      password,
      confirmPassword,
    );
    if (usernameError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      state = SignUpState(
        usernameError: usernameError,
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
      );
      return false;
    }

    state = const SignUpState(isLoading: true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signUp(
            username: username.trim(),
            password: password,
            confirmPassword: confirmPassword,
          );
      ref.read(authSessionProvider.notifier).setSession(session);
      ref.invalidate(profileViewModelProvider);
      if (ref.mounted) state = const SignUpState();
      return true;
    } on AppException catch (e) {
      if (!ref.mounted) return false;
      // 409: tên đã có người dùng -> báo ngay dưới ô tên đăng nhập
      state = e.statusCode == 409
          ? const SignUpState(
              usernameError: 'Tên đăng nhập này đã được sử dụng.',
            )
          : SignUpState(errorMessage: e.message);
      return false;
    }
  }
}
