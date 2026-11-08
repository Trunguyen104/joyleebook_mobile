import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_paths.dart';
import '../../auth/view_models/auth_session_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/widgets/joylee_avatar.dart';
import '../../core/widgets/joylee_button.dart';
import '../view_models/profile_view_model.dart';

/// Màn hình Cài đặt (SettingsScreen)
/// Gom nhóm các thiết lập:
/// 1. Tài khoản: Chỉnh sửa hồ sơ, Đổi mật khẩu, Đăng xuất
/// 2. Giao diện: Chế độ Sáng / Tối / Hệ thống
/// 3. Thông tin ứng dụng
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final sessionAsync = ref.watch(authSessionProvider);
    final isSignedIn = sessionAsync.value != null;
    final profileAsync = isSignedIn
        ? ref.watch(profileViewModelProvider)
        : null;
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(title: const Text('Cài đặt')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space4,
            vertical: AppDimensions.space4,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PHẦN 1: TÀI KHOẢN
                  _buildSectionHeader('TÀI KHOẢN', colors),
                  const SizedBox(height: AppDimensions.space2),
                  if (isSignedIn) ...[
                    // Card tóm tắt hồ sơ người dùng
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space4),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        border: Border.all(color: colors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          JoyleeAvatar(
                            initials:
                                profileAsync?.value?.initials ??
                                sessionAsync.value?.username
                                    .substring(0, 1)
                                    .toUpperCase() ??
                                '?',
                            imageUrl: profileAsync?.value?.avatarUrl,
                            size: JoyleeAvatarSize.lg,
                            semanticLabel: 'Ảnh đại diện',
                          ),
                          const SizedBox(width: AppDimensions.space3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profileAsync?.value?.name ??
                                      sessionAsync.value?.username ??
                                      '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@${sessionAsync.value?.username ?? ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space3),
                    _buildSettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Chỉnh sửa hồ sơ',
                      subtitle: 'Tên hiển thị, giới thiệu và ảnh đại diện',
                      colors: colors,
                      onTap: () => context.push(AppPaths.editProfile),
                    ),
                    const SizedBox(height: AppDimensions.space2),
                    _buildSettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Đổi mật khẩu',
                      subtitle: 'Cập nhật mật khẩu bảo mật tài khoản',
                      colors: colors,
                      onTap: () => context.push(AppPaths.changePassword),
                    ),
                  ] else ...[
                    _buildSettingsTile(
                      icon: Icons.login_rounded,
                      title: 'Đăng nhập / Đăng ký',
                      subtitle: 'Đăng nhập để xem tủ sách và lưu tiến độ đọc',
                      colors: colors,
                      onTap: () => context.push(AppPaths.signIn),
                    ),
                  ],

                  const SizedBox(height: AppDimensions.space6),

                  // PHẦN 2: GIAO DIỆN & TRẢI NGHIỆM
                  _buildSectionHeader('GIAO DIỆN & TRẢI NGHIỆM', colors),
                  const SizedBox(height: AppDimensions.space2),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space4),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(color: colors.borderDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              color: colors.primaryBrand,
                              size: 22,
                            ),
                            const SizedBox(width: AppDimensions.space2),
                            Text(
                              'Chế độ hiển thị',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space1),
                        Text(
                          'Tùy chỉnh tông màu đọc sách theo sở thích và điều kiện ánh sáng.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space4),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_outlined),
                                label: Text('Sáng'),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_outlined),
                                label: Text('Tối'),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.system,
                                icon: Icon(Icons.brightness_auto_outlined),
                                label: Text('Hệ thống'),
                              ),
                            ],
                            selected: {currentThemeMode},
                            onSelectionChanged: (newSelection) {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeMode(newSelection.first);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PHẦN 3: ĐĂNG XUẤT (NẾU ĐÃ ĐĂNG NHẬP)
                  if (isSignedIn) ...[
                    const SizedBox(height: AppDimensions.space6),
                    _buildSectionHeader('PHIÊN ĐĂNG NHẬP', colors),
                    const SizedBox(height: AppDimensions.space2),
                    _buildSettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: colors.danger,
                      title: 'Đăng xuất',
                      titleColor: colors.danger,
                      subtitle: 'Đăng xuất tài khoản khỏi thiết bị này',
                      colors: colors,
                      onTap: () => _confirmSignOut(context, ref),
                    ),
                  ],

                  const SizedBox(height: AppDimensions.space6),

                  // PHẦN 4: HỆ THỐNG & KẾT NỐI
                  _buildSectionHeader('HỆ THỐNG & KẾT NỐI', colors),
                  const SizedBox(height: AppDimensions.space2),
                  _buildSettingsTile(
                    icon: Icons.router_outlined,
                    title: 'Kiểm tra Gateway',
                    subtitle: 'Chẩn đoán kết nối và trạng thái microservice',
                    colors: colors,
                    onTap: () => context.push(AppPaths.gateway),
                  ),

                  const SizedBox(height: AppDimensions.space6),

                  // PHẦN 5: THÔNG TIN ỨNG DỤNG
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 32,
                          color: colors.primaryBrand.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: AppDimensions.space1),
                        Text(
                          'JoyleeBook Mobile',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phiên bản 1.0.0 (Warm Editorial)',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space1),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: colors.textMuted,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    Color? titleColor,
    required String subtitle,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colors.bgSurface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space4,
            vertical: AppDimensions.space3,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (iconColor ?? colors.primaryBrand).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? colors.primaryBrand,
                ),
              ),
              const SizedBox(width: AppDimensions.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Bạn sẽ cần đăng nhập lại để xem hồ sơ và thống kê đọc của mình.',
        ),
        actions: [
          JoyleeButton(
            label: 'Hủy',
            variant: JoyleeButtonVariant.ghost,
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          JoyleeButton(
            label: 'Đăng xuất',
            variant: JoyleeButtonVariant.danger,
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    await ref.read(authSessionProvider.notifier).signOut();
    if (!context.mounted) return;

    messenger.showSnackBar(const SnackBar(content: Text('Đã đăng xuất')));
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    }
  }
}
