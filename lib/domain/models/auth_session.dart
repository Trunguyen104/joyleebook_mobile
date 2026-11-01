import 'package:flutter/foundation.dart';

import 'user_profile.dart';

/// Phiên đăng nhập hiện tại (đọc từ claims của access token)
@immutable
class AuthSession {
  final String userId;
  final String username;
  final UserRole role;

  const AuthSession({
    required this.userId,
    required this.username,
    required this.role,
  });

  @override
  bool operator ==(Object other) =>
      other is AuthSession &&
      other.userId == userId &&
      other.username == username &&
      other.role == role;

  @override
  int get hashCode => Object.hash(userId, username, role);
}
