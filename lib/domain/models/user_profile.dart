import 'package:flutter/foundation.dart';
import '../../data/dtos/profile_dto.dart';
import '../../data/dtos/reading_stats_dto.dart';

/// Vai trò tài khoản (backend trả "Reader" / "Author" / "Admin")
enum UserRole {
  reader,
  author,
  admin;

  /// Không phân biệt hoa thường; giá trị lạ hoặc null coi là Độc giả
  static UserRole fromString(String? value) => switch (value?.toLowerCase()) {
    'admin' => UserRole.admin,
    'author' => UserRole.author,
    _ => UserRole.reader,
  };

  /// Nhãn hiển thị tiếng Việt
  String get label => switch (this) {
    UserRole.reader => 'Độc giả',
    UserRole.author => 'Tác giả',
    UserRole.admin => 'Quản trị viên',
  };
}

/// Thống kê đọc của người dùng
@immutable
class ReadingStats {
  final int seriesStarted;
  final int chaptersCompleted;
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime? lastReadAt;

  /// Số ngày của kỳ thống kê gần đây (repository đang hỏi 30 ngày)
  final int periodDays;

  /// Số chương đọc xong trong kỳ
  final int chaptersCompletedInPeriod;

  /// Số ngày có đọc trong kỳ
  final int activeDaysInPeriod;

  const ReadingStats({
    this.seriesStarted = 0,
    this.chaptersCompleted = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.lastReadAt,
    this.periodDays = 0,
    this.chaptersCompletedInPeriod = 0,
    this.activeDaysInPeriod = 0,
  });

  /// Chuyển đổi an toàn từ DTO
  factory ReadingStats.fromDto(ReadingStatsDto dto) {
    return ReadingStats(
      seriesStarted: dto.seriesStarted,
      chaptersCompleted: dto.chaptersCompleted,
      currentStreakDays: dto.currentStreakDays,
      longestStreakDays: dto.longestStreakDays,
      lastReadAt: dto.lastReadAtUtc?.toLocal(),
      periodDays: dto.periodDays,
      chaptersCompletedInPeriod: dto.chaptersCompletedInPeriod,
      activeDaysInPeriod: dto.activeDaysInPeriod,
    );
  }

  /// Tỉ lệ số ngày có đọc trong kỳ (0.0 – 1.0), dùng cho thanh tiến độ
  double get activeRatio =>
      periodDays <= 0 ? 0 : (activeDaysInPeriod / periodDays).clamp(0.0, 1.0);

  ReadingStats copyWith({
    int? seriesStarted,
    int? chaptersCompleted,
    int? currentStreakDays,
    int? longestStreakDays,
    DateTime? lastReadAt,
    int? periodDays,
    int? chaptersCompletedInPeriod,
    int? activeDaysInPeriod,
  }) {
    return ReadingStats(
      seriesStarted: seriesStarted ?? this.seriesStarted,
      chaptersCompleted: chaptersCompleted ?? this.chaptersCompleted,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      periodDays: periodDays ?? this.periodDays,
      chaptersCompletedInPeriod:
          chaptersCompletedInPeriod ?? this.chaptersCompletedInPeriod,
      activeDaysInPeriod: activeDaysInPeriod ?? this.activeDaysInPeriod,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingStats &&
          runtimeType == other.runtimeType &&
          seriesStarted == other.seriesStarted &&
          chaptersCompleted == other.chaptersCompleted &&
          currentStreakDays == other.currentStreakDays &&
          longestStreakDays == other.longestStreakDays &&
          lastReadAt == other.lastReadAt &&
          periodDays == other.periodDays &&
          chaptersCompletedInPeriod == other.chaptersCompletedInPeriod &&
          activeDaysInPeriod == other.activeDaysInPeriod;

  @override
  int get hashCode => Object.hash(
        seriesStarted,
        chaptersCompleted,
        currentStreakDays,
        longestStreakDays,
        lastReadAt,
        periodDays,
        chaptersCompletedInPeriod,
        activeDaysInPeriod,
      );
}

/// PURE DOMAIN MODEL - Hồ sơ người dùng đang đăng nhập.
@immutable
class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? email;
  final UserRole role;
  final ReadingStats stats;

  const UserProfile({
    required this.id,
    required this.username,
    required this.role,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.email,
    this.stats = const ReadingStats(),
  });

  /// Chuyển đổi an toàn từ DTO
  factory UserProfile.fromDto(ProfileDto profile, [ReadingStatsDto? statsDto]) {
    return UserProfile(
      id: profile.id,
      username: profile.username,
      displayName: profile.displayName,
      bio: profile.bio,
      avatarUrl: profile.avatarUrl,
      email: profile.email,
      role: UserRole.fromString(profile.role),
      stats: statsDto != null
          ? ReadingStats.fromDto(statsDto)
          : const ReadingStats(),
    );
  }

  /// Tên hiển thị: ưu tiên displayName, chưa đặt thì dùng username
  String get name {
    final trimmed = displayName?.trim();
    return (trimmed == null || trimmed.isEmpty) ? username : trimmed;
  }

  /// Chữ cái đầu cho avatar mặc định khi chưa có avatarUrl
  String get initials =>
      name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

  /// Có ảnh đại diện để tải hay không
  bool get hasAvatar => avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? email,
    UserRole? role,
    ReadingStats? stats,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      role: role ?? this.role,
      stats: stats ?? this.stats,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          displayName == other.displayName &&
          bio == other.bio &&
          avatarUrl == other.avatarUrl &&
          email == other.email &&
          role == other.role &&
          stats == other.stats;

  @override
  int get hashCode => Object.hash(
        id,
        username,
        displayName,
        bio,
        avatarUrl,
        email,
        role,
        stats,
      );
}
