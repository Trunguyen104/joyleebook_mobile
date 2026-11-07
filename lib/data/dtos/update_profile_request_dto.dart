import 'package:flutter/foundation.dart';

/// Body gửi lên PUT /api/profiles/me.
/// Luôn gửi đủ 3 khóa: giá trị null tương ứng với việc xóa trường đó.
@immutable
class UpdateProfileRequestDto {
  const UpdateProfileRequestDto({
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
  });

  final String? displayName;
  final String? bio;
  final String? avatarUrl;

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'bio': bio,
    'avatarUrl': avatarUrl,
  };
}
