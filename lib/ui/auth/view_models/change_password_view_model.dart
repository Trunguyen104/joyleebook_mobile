import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/api_exceptions.dart';
import 'auth_session_view_model.dart';
import 'auth_validators.dart';

@immutable
class ChangePasswordState {
  const ChangePasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.currentPasswordError,
    this.passwordError,
    this.confirmPasswordError,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? currentPasswordError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? errorMessage;
}

final changePasswordViewModelProvider =
    NotifierProvider.autoDispose<ChangePasswordViewModel, ChangePasswordState>(
      ChangePasswordViewModel.new,
    );

class ChangePasswordViewModel extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    if (state.isLoading || state.isSuccess) return false;
    final currentError = currentPassword.isEmpty
        ? 'Vui lòng nhập mật khẩu hiện tại'
        : currentPassword.length > 128
        ? 'Mật khẩu hiện tại không quá 128 ký tự'
        : null;
    final passwordError =
        validatePassword(newPassword) ??
        (newPassword == currentPassword
            ? 'Mật khẩu mới phải khác mật khẩu hiện tại'
            : null);
    final confirmError = validateConfirmPassword(
      newPassword,
      confirmNewPassword,
    );
    if (currentError != null || passwordError != null || confirmError != null) {
      state = ChangePasswordState(
        currentPasswordError: currentError,
        passwordError: passwordError,
        confirmPasswordError: confirmError,
      );
      return false;
    }

    state = const ChangePasswordState(isLoading: true);
    try {
      await ref
          .read(authSessionProvider.notifier)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmNewPassword: confirmNewPassword,
          );
      if (ref.mounted) state = const ChangePasswordState(isSuccess: true);
      return true;
    } on AppException catch (e) {
      if (ref.mounted) {
        state = e.message == 'Mật khẩu hiện tại không đúng.'
            ? ChangePasswordState(currentPasswordError: e.message)
            : ChangePasswordState(errorMessage: e.message);
      }
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = const ChangePasswordState(
          errorMessage: 'Không thể đổi mật khẩu. Vui lòng thử lại.',
        );
      }
      return false;
    }
  }
}
