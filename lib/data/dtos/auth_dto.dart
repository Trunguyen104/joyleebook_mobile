import 'package:flutter/foundation.dart';

/// Body gửi lên POST /api/auth/sign-in
@immutable
class SignInRequestDto {
  final String username;
  final String password;

  const SignInRequestDto({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

/// Body gửi lên POST /api/auth/sign-up (backend không nhận email)
@immutable
class SignUpRequestDto {
  final String username;
  final String password;
  final String confirmPassword;

  const SignUpRequestDto({
    required this.username,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    'confirmPassword': confirmPassword,
  };
}

/// Body gửi lên PUT /api/auth/me/password
@immutable
class ChangePasswordRequestDto {
  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  Map<String, dynamic> toJson() => {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
    'confirmNewPassword': confirmNewPassword,
  };
}

/// Body gửi lên POST /api/auth/google.
@immutable
class GoogleSignInRequestDto {
  const GoogleSignInRequestDto({required this.idToken});

  final String idToken;

  Map<String, dynamic> toJson() => {'idToken': idToken};
}

/// Phản hồi chung của sign-in / sign-up / refresh
@immutable
class TokenResponseDto {
  final String accessToken;

  /// Bản backend đang deploy chưa trả refreshToken -> có thể null
  final String? refreshToken;

  const TokenResponseDto({required this.accessToken, this.refreshToken});

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) {
    final refreshToken = json['refreshToken'] as String?;
    return TokenResponseDto(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: (refreshToken?.isEmpty ?? true) ? null : refreshToken,
    );
  }

  /// Chỉ bắt buộc có accessToken
  bool get isValid => accessToken.isNotEmpty;
}

/// Body gửi lên POST /api/auth/forgot-password
@immutable
class ForgotPasswordRequestDto {
  final String email;

  const ForgotPasswordRequestDto({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

/// Body gửi lên POST /api/auth/reset-password
@immutable
class ResetPasswordRequestDto {
  final String email;
  final String token;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordRequestDto({
    required this.email,
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'token': token,
    'newPassword': newPassword,
    'confirmPassword': confirmPassword,
  };
}
