import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_exceptions.dart';
import 'auth_validators.dart';

enum ResetPasswordStep { credentials, password, success }

@immutable
class ResetPasswordState {
  const ResetPasswordState({
    this.step = ResetPasswordStep.credentials,
    this.isLoading = false,
    this.emailError,
    this.tokenError,
    this.passwordError,
    this.confirmPasswordError,
    this.errorMessage,
  });

  final ResetPasswordStep step;
  final bool isLoading;
  final String? emailError;
  final String? tokenError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? errorMessage;
}

final resetPasswordViewModelProvider =
    NotifierProvider.autoDispose<ResetPasswordViewModel, ResetPasswordState>(
      ResetPasswordViewModel.new,
    );

class ResetPasswordViewModel extends Notifier<ResetPasswordState> {
  String _email = '';
  String _token = '';

  @override
  ResetPasswordState build() => const ResetPasswordState();

  Future<void> verify({required String email, required String token}) async {
    if (state.isLoading || state.step != ResetPasswordStep.credentials) return;
    // Cho phép dán cả liên kết trong email thay vì tách mã thủ công.
    final Map<String, String> parameters;
    var isLink = false;
    try {
      final link = Uri.tryParse(token.trim());
      isLink = link?.hasScheme == true || link?.hasQuery == true;
      parameters = link?.hasQuery == true
          ? link!.queryParameters
          : Uri.tryParse(link?.fragment ?? '')?.queryParameters ??
                const <String, String>{};
    } on FormatException {
      state = const ResetPasswordState(
        tokenError: 'Liên kết khôi phục không đúng định dạng. Vui lòng sao chép lại từ email.',
      );
      return;
    }
    final resolvedEmail = (parameters['email'] ?? email).trim();
    final resolvedToken = (parameters['token'] ?? (isLink ? '' : token)).trim();
    final emailError = validateEmail(resolvedEmail);
    final tokenError = resolvedToken.isEmpty
        ? 'Vui lòng nhập mã khôi phục trong email'
        : null;
    if (emailError != null || tokenError != null) {
      state = ResetPasswordState(
        emailError: emailError,
        tokenError: tokenError,
      );
      return;
    }

    state = const ResetPasswordState(isLoading: true);
    try {
      final valid = await ref
          .read(authRepositoryProvider)
          .validateResetToken(email: resolvedEmail, token: resolvedToken);
      if (!ref.mounted) return;
      if (!valid) {
        state = const ResetPasswordState(
          tokenError: 'Mã khôi phục không hợp lệ hoặc đã hết hạn. Vui lòng yêu cầu mã mới.',
        );
        return;
      }
      _email = resolvedEmail;
      _token = resolvedToken;
      state = const ResetPasswordState(step: ResetPasswordStep.password);
    } catch (error) {
      if (!ref.mounted) return;
      state = ResetPasswordState(errorMessage: _message(error));
    }
  }

  Future<void> submit({
    required String password,
    required String confirmPassword,
  }) async {
    if (state.isLoading || state.step != ResetPasswordStep.password) return;
    final passwordError = validatePassword(password);
    final confirmError = validateConfirmPassword(password, confirmPassword);
    if (passwordError != null || confirmError != null) {
      state = ResetPasswordState(
        step: ResetPasswordStep.password,
        passwordError: passwordError,
        confirmPasswordError: confirmError,
      );
      return;
    }

    state = const ResetPasswordState(
      step: ResetPasswordStep.password,
      isLoading: true,
    );
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: _email,
            token: _token,
            newPassword: password,
            confirmPassword: confirmPassword,
          );
      if (!ref.mounted) return;
      _email = '';
      _token = '';
      state = const ResetPasswordState(step: ResetPasswordStep.success);
    } catch (error) {
      if (!ref.mounted) return;
      // Mã có thể hết hạn sau bước kiểm tra, trước khi gửi mật khẩu mới.
      if (error is AppException &&
          (error.statusCode == 400 || error.statusCode == 401)) {
        _email = '';
        _token = '';
        state = const ResetPasswordState(
          tokenError: 'Không thể đặt lại mật khẩu. Vui lòng kiểm tra mã khôi phục hoặc yêu cầu mã mới.',
        );
      } else {
        state = ResetPasswordState(
          step: ResetPasswordStep.password,
          errorMessage: _message(error),
        );
      }
    }
  }

  String _message(Object error) => error is AppException
      ? error.message
      : 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
}
