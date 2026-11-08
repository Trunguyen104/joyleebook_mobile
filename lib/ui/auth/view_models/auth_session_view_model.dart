import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models/auth_session.dart';

/// Trạng thái đăng nhập của cả app: null = chưa đăng nhập.
/// GoRouter theo dõi provider này để tự chuyển hướng (xem app_router.dart).
final authSessionProvider =
    AsyncNotifierProvider<AuthSessionViewModel, AuthSession?>(
      AuthSessionViewModel.new,
      retry: (retryCount, error) => null,
    );

class AuthSessionViewModel extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() {
    // Interceptor báo phiên hết hạn (refresh thất bại) -> về trạng thái chưa đăng nhập
    ref.listen(sessionExpiredProvider, (_, expired) {
      if (expired) state = const AsyncData(null);
    });
    return ref.read(authRepositoryProvider).restoreSession();
  }

  /// Gọi sau khi đăng nhập / đăng ký thành công
  void setSession(AuthSession session) {
    ref.read(sessionExpiredProvider.notifier).reset();
    state = AsyncData(session);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  /// Cập nhật phiên ngay cả khi người dùng đã rời form trong lúc gửi yêu cầu.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmNewPassword: confirmNewPassword,
        );
    if (ref.mounted) state = const AsyncData(null);
  }
}
