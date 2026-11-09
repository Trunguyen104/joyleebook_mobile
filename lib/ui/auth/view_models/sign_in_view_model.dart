import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_exceptions.dart';
import '../../profile/view_models/profile_view_model.dart';
import 'auth_session_view_model.dart';
import 'auth_validators.dart';

@immutable
class SignInState {
  final bool isLoading;
  final String? usernameError;
  final String? passwordError;

  /// Lỗi chung từ máy chủ (sai mật khẩu, mất mạng...) -> hiện SnackBar
  final String? errorMessage;

  const SignInState({
    this.isLoading = false,
    this.usernameError,
    this.passwordError,
    this.errorMessage,
  });
}

/// autoDispose: rời màn hình thì form được làm sạch
final signInViewModelProvider =
    NotifierProvider.autoDispose<SignInViewModel, SignInState>(
      SignInViewModel.new,
    );

class SignInViewModel extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  /// Trả về true khi đăng nhập thành công
  Future<bool> submit({
    required String username,
    required String password,
  }) async {
    // Chặn bấm 2 lần khi request trước chưa xong
    if (state.isLoading) return false;

    final usernameError = validateRequired(
      username,
      'Vui lòng nhập tên đăng nhập hoặc email',
    );
    final passwordError = validateRequired(password, 'Vui lòng nhập mật khẩu');
    if (usernameError != null || passwordError != null) {
      state = SignInState(
        usernameError: usernameError,
        passwordError: passwordError,
      );
      return false;
    }

    state = const SignInState(isLoading: true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signIn(username: username.trim(), password: password);
      ref.read(authSessionProvider.notifier).setSession(session);
      ref.invalidate(profileViewModelProvider);
      if (ref.mounted) state = const SignInState();
      return true;
    } on AppException catch (e) {
      if (ref.mounted) state = SignInState(errorMessage: e.message);
      return false;
    }
  }
}
