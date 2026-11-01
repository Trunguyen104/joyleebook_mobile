import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_exceptions.dart';
import 'auth_validators.dart';

@immutable
class ForgotPasswordState {
  final bool isLoading;
  final bool isSuccess;
  final String? emailError;

  /// Lỗi chung từ máy chủ (lỗi kết nối, 500...) -> hiện SnackBar
  final String? errorMessage;

  /// Email đã gửi thành công để hiển thị ở màn hình xác nhận
  final String? submittedEmail;

  const ForgotPasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.emailError,
    this.errorMessage,
    this.submittedEmail,
  });
}

/// autoDispose: rời màn hình thì form được làm sạch
final forgotPasswordViewModelProvider =
    NotifierProvider.autoDispose<ForgotPasswordViewModel, ForgotPasswordState>(
      ForgotPasswordViewModel.new,
    );

class ForgotPasswordViewModel extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  /// Trả về true khi yêu cầu đặt lại mật khẩu gửi thành công
  Future<bool> submit({required String email}) async {
    // Chặn bấm 2 lần khi request trước chưa xong
    if (state.isLoading) return false;

    final trimmedEmail = email.trim();
    final emailError = validateEmail(trimmedEmail);
    if (emailError != null) {
      state = ForgotPasswordState(emailError: emailError);
      return false;
    }

    state = const ForgotPasswordState(isLoading: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(email: trimmedEmail);
      if (ref.mounted) {
        state = ForgotPasswordState(
          isSuccess: true,
          submittedEmail: trimmedEmail,
        );
      }
      return true;
    } on AppException catch (e) {
      if (ref.mounted) {
        state = ForgotPasswordState(errorMessage: e.message);
      }
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = const ForgotPasswordState(
          errorMessage: 'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
        );
      }
      return false;
    }
  }

  /// Khôi phục về trạng thái nhập để người dùng có thể gửi lại bằng email khác
  void reset() {
    state = const ForgotPasswordState();
  }
}
