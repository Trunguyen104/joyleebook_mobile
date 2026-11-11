import 'package:flutter/foundation.dart';

@immutable
class ProfileDto {
  final String id;
  final String username;
  final String? role;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? email;
  final DateTime? updatedAtUtc;

  const ProfileDto({
    required this.id,
    required this.username,
    this.role,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.email,
    this.updatedAtUtc,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final account =
        (json['account'] ?? json['Account']) as Map<String, dynamic>?;

    return ProfileDto(
      id: (json['id'] ?? json['Id'])?.toString() ?? '',
      username: (json['username'] ?? json['Username'])?.toString() ?? '',
      role: (json['role'] ?? json['Role'])?.toString(),
      displayName: (json['displayName'] ?? json['DisplayName'])?.toString(),
      bio: (json['bio'] ?? json['Bio'])?.toString(),
      avatarUrl: (json['avatarUrl'] ?? json['AvatarUrl'] ?? json['avatar_url'])
          ?.toString(),
      email:
          (json['email'] ??
                  json['Email'] ??
                  account?['email'] ??
                  account?['Email'])
              ?.toString(),
      // Chuỗi rỗng hoặc sai định dạng thì trả về null thay vì làm sập app
      updatedAtUtc: DateTime.tryParse(
        (json['updatedAtUtc'] ?? json['UpdatedAtUtc'])?.toString() ?? '',
      ),
    );
  }
}
