import 'package:flutter/material.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_colors.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_dimensions.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_avatar.dart';

/// Phần đầu hồ sơ (căn giữa): avatar 96, tên, @username, badge vai trò, giới thiệu
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final UserProfile profile; // widget của feature được phép nhận domain model

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final bio = profile.bio?.trim();

    return Column(
      children: [
        JoyleeAvatar(
          initials: profile.initials, // "phuc123" -> "P"
          imageUrl: profile.avatarUrl,
          size: JoyleeAvatarSize.xl,
          semanticLabel: 'Ảnh đại diện của ${profile.name}',
        ),
        const SizedBox(height: AppDimensions.space4),
        // Heading/H3: 22px semibold, letter-spacing -0.03em
        Text(
          profile.name, // displayName, nếu trống thì dùng username
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.66,
            color: colors.textPrimary,
          ),
        ),
        // Đã đặt tên hiển thị thì ghi thêm @username bên dưới
        if (profile.name != profile.username) ...[
          const SizedBox(height: AppDimensions.space1),
          Text(
            '@${profile.username}',
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
        ],
        const SizedBox(height: AppDimensions.space3),
        _RoleBadge(role: profile.role),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.space4),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Badge vai trò, tone "brand" của Status Badge (§5.4):
/// nền brand-subtle, chữ text/brand, cao 28, bo tròn, Caption 12/16 đậm 600.
/// Có icon kèm nhãn để không chỉ dựa vào màu.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  IconData get _icon => switch (role) {
    UserRole.reader => Icons.menu_book_outlined,
    UserRole.author => Icons.edit_outlined,
    UserRole.admin => Icons.shield_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space3),
      decoration: BoxDecoration(
        color: colors.bgBrandSubtle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: colors.textBrand),
          const SizedBox(width: AppDimensions.space1),
          Text(
            role.label, // "Độc giả" / "Tác giả" / ...
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: colors.textBrand,
            ),
          ),
        ],
      ),
    );
  }
}
