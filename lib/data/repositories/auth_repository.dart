import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_endpoints.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/user_profile.dart';
import '../dtos/auth_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';
import '../services/auth_interceptor.dart';
import '../services/jwt_reader.dart';
import '../services/token_storage.dart';

/// REPOSITORY - Đăng nhập, đăng ký, đăng xuất.
/// Lưu/xóa token trong TokenStorage và trả về AuthSession cho ViewModel.
class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepository(this._dio, this._tokenStorage);

  /// 401 ở đây nghĩa là sai tài khoản, không phải hết phiên -> không refresh
  static final _skipRefresh = Options(
    extra: {AuthInterceptor.skipAuthRefresh: true},
  );

  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authSignIn,
        data: SignInRequestDto(username: username, password: password).toJson(),
        options: _skipRefresh,
      );
      return await _saveSession(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AppException(
          message: 'Tên đăng nhập hoặc mật khẩu không đúng.',
          statusCode: 401,
        );
      }
      throw AppException.fromDio(e);
    }
  }

  Future<AuthSession> signInWithGoogle({required String idToken}) async {
    if (idToken.trim().isEmpty || idToken.length > 4096) {
      throw const AppException(
        message: 'Thông tin đăng nhập Google không hợp lệ.',
      );
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authGoogle,
        data: GoogleSignInRequestDto(idToken: idToken).toJson(),
        options: _skipRefresh,
      );
      return await _saveSession(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AppException(
          message:
              'Không thể xác minh tài khoản Google. Vui lòng đăng nhập lại.',
          statusCode: 401,
        );
      }
      if (e.response?.statusCode == 503) {
        throw const AppException(
          message:
              'Đăng nhập Google tạm thời không khả dụng. Vui lòng thử lại sau.',
          statusCode: 503,
        );
      }
      throw AppException.fromDio(e);
    }
  }

  /// Backend trả về token ngay khi đăng ký (201) -> đăng nhập luôn
  Future<AuthSession> signUp({
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authSignUp,
        data: SignUpRequestDto(
          username: username,
          password: password,
          confirmPassword: confirmPassword,
        ).toJson(),
        options: _skipRefresh,
      );
      return await _saveSession(response.data);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// Báo backend thu hồi phiên. Dù backend lỗi hay mất mạng,
  /// token trên máy vẫn luôn bị xóa -> người dùng chắc chắn đã đăng xuất.
  Future<void> signOut() async {
    try {
      await _dio.post<void>(ApiEndpoints.authSignOut, options: _skipRefresh);
    } on DioException {
      // Bỏ qua: 401 (token đã hết hạn) hay lỗi mạng đều coi như đã đăng xuất
    } finally {
      await _tokenStorage.clear();
    }
  }

  /// Backend thu hồi phiên sau khi đổi mật khẩu; xóa token trên máy khi thành công.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      await _dio.put<void>(
        ApiEndpoints.authChangePassword,
        data: ChangePasswordRequestDto(
          currentPassword: currentPassword,
          newPassword: newPassword,
          confirmNewPassword: confirmNewPassword,
        ).toJson(),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 400 &&
          data is Map &&
          data['message'] == 'Current password is incorrect.') {
        throw const AppException(
          message: 'Mật khẩu hiện tại không đúng.',
          statusCode: 400,
        );
      }
      throw AppException.fromDio(e);
    }
    await _tokenStorage.clear();
  }

  /// Gửi yêu cầu đặt lại mật khẩu qua email
  /// Theo OWASP: API luôn trả về 200 kể cả email không tồn tại để tránh rò rỉ thông tin
  Future<void> forgotPassword({required String email}) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.authForgotPassword,
        data: ForgotPasswordRequestDto(email: email.trim()).toJson(),
        options: _skipRefresh,
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// Đặt lại mật khẩu mới bằng token đã nhận qua email
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.authResetPassword,
        data: ResetPasswordRequestDto(
          email: email.trim(),
          token: token.trim(),
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ).toJson(),
        options: _skipRefresh,
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// Kiểm tra token đặt lại mật khẩu có còn hiệu lực không
  Future<bool> validateResetToken({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.authValidateResetToken,
        queryParameters: {'email': email.trim(), 'token': token.trim()},
        options: _skipRefresh,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) return false;
      throw AppException.fromDio(e);
    }
  }

  /// Mở app: khôi phục phiên từ token đã lưu (không gọi mạng).
  /// Access token hết hạn mà còn refresh token thì vẫn giữ phiên,
  /// interceptor sẽ tự refresh ở request đầu tiên.
  Future<AuthSession?> restoreSession() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null) return null;

    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null && _isExpired(accessToken)) {
      // Hết hạn và không có cách làm mới -> coi như chưa đăng nhập
      await _tokenStorage.clear();
      return null;
    }
    return _sessionFromToken(accessToken);
  }

  /// Đọc claim "exp" (số giây Unix). Không có "exp" thì coi như còn hạn.
  bool _isExpired(String accessToken) {
    final exp = readJwtClaims(accessToken)['exp'];
    if (exp is! num) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    return DateTime.now().isAfter(expiresAt);
  }

  Future<AuthSession> _saveSession(Map<String, dynamic>? data) async {
    final dto = TokenResponseDto.fromJson(data ?? const {});
    if (!dto.isValid) {
      throw const AppException(
        message: 'Máy chủ trả về dữ liệu đăng nhập không hợp lệ.',
      );
    }
    await _tokenStorage.saveTokens(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
    );
    return _sessionFromToken(dto.accessToken);
  }

  /// Tên claim theo JwtTokenService của backend (.NET dùng URI dài cho name/role)
  AuthSession _sessionFromToken(String accessToken) {
    final claims = readJwtClaims(accessToken);
    return AuthSession(
      userId: claims['sub']?.toString() ?? '',
      username:
          (claims['unique_name'] ??
                  claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'])
              ?.toString() ??
          '',
      role: UserRole.fromString(
        (claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
                claims['role'])
            ?.toString(),
      ),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});
