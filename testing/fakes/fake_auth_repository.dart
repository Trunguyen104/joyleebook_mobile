import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/auth_session.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';

const fakeSession = AuthSession(
  userId: '115a1ebc-2cb0-41e5-9690-7166fc73b753',
  username: 'phuc123',
  role: UserRole.reader,
);

/// Repository giả cho test: không gọi mạng
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.savedSession, this.error});

  /// Phiên "đã lưu trên máy" khi mở app (null = chưa đăng nhập)
  AuthSession? savedSession;

  /// Lỗi ném ra khi đăng nhập / đăng ký
  AppException? error;

  int signInCallCount = 0;
  int signUpCallCount = 0;
  int signOutCallCount = 0;
  int changePasswordCallCount = 0;
  String? lastCurrentPassword;
  String? lastNewPassword;
  String? lastConfirmNewPassword;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    changePasswordCallCount++;
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    lastConfirmNewPassword = confirmNewPassword;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
    savedSession = null;
  }

  int forgotPasswordCallCount = 0;
  String? lastForgotPasswordEmail;
  int resetPasswordCallCount = 0;
  int validateResetTokenCallCount = 0;
  String? lastResetEmail;
  String? lastResetToken;
  String? lastResetPassword;
  String? lastResetConfirmPassword;
  bool isTokenValid = true;

  @override
  Future<AuthSession?> restoreSession() async => savedSession;

  @override
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    signInCallCount++;
    // Trễ nhẹ để test thấy được trạng thái loading
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
    return savedSession = fakeSession;
  }

  @override
  Future<AuthSession> signUp({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    signUpCallCount++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
    return savedSession = fakeSession;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    savedSession = null;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    forgotPasswordCallCount++;
    lastForgotPasswordEmail = email;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    resetPasswordCallCount++;
    lastResetEmail = email;
    lastResetToken = token;
    lastResetPassword = newPassword;
    lastResetConfirmPassword = confirmPassword;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
  }

  @override
  Future<bool> validateResetToken({
    required String email,
    required String token,
  }) async {
    validateResetTokenCallCount++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
    return isTokenValid;
  }
}
