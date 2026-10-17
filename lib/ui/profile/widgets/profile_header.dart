import 'package:flutter/material.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_colors.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_dimensions.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.profile});

  final UserProfile profile; // widget của feature được phép nhận domain model

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bio = profile.bio?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colors.bgSurfaceSubtle,
              foregroundColor: colors.primaryBrand,
              backgroundImage: profile.hasAvatar
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              // Ảnh lỗi (link hỏng, mất mạng) thì bỏ qua, không làm sập app
              onBackgroundImageError: profile.hasAvatar ? (_, _) {} : null,
              child: profile.hasAvatar
                  ? null
                  : Text(
                      profile.initials, // "phuc123" -> "P"
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: AppDimensions.space4),
            Expanded(
              // BẮT BUỘC: không có Expanded, tên dài sẽ tràn ngang
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name, // displayName, nếu trống thì dùng username
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  // Đã đặt tên hiển thị thì ghi thêm @username bên dưới
                  if (profile.name != profile.username)
                    Text(
                      '@${profile.username}',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  const SizedBox(height: AppDimensions.space1),
                  Text(
                    profile.role.label, // "Độc giả" / "Tác giả" / ...
                    style: TextStyle(
                      color: colors.primaryBrand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.space4),
          Text(bio, style: TextStyle(color: colors.textPrimary, height: 1.5)),
        ],
      ],
    );
  }
}
