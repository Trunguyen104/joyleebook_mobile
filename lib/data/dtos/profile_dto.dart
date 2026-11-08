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
    return ProfileDto(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String?,
      displayName: json['displayName'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      email: json['email'] as String?,
      // Chuỗi rỗng hoặc sai định dạng thì trả về null thay vì làm sập app
      updatedAtUtc: DateTime.tryParse(json['updatedAtUtc']?.toString() ?? ''),
    );
  }
}
