import 'package:flutter/foundation.dart';

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

  /// Tỉ lệ số ngày có đọc trong kỳ (0.0 – 1.0), dùng cho thanh tiến độ
  double get activeRatio =>
      periodDays <= 0 ? 0 : (activeDaysInPeriod / periodDays).clamp(0.0, 1.0);
}

/// PURE DOMAIN MODEL - Hồ sơ người dùng đang đăng nhập.
/// Không import DTO: việc chuyển DTO -> model nằm ở ProfileRepository.
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
}
