import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../data/services/image_picker_service.dart';
import '../../../domain/models/user_profile.dart';
import '../../../routing/app_paths.dart';
import '../../auth/view_models/auth_session_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_avatar.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_text_field.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/profile_validators.dart';
import '../view_models/profile_view_model.dart';

/// Màn hình chỉnh sửa hồ sơ: tên hiển thị, giới thiệu, ảnh đại diện.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authSessionProvider);
    final session = authState.value;
    final state = ref.watch(profileViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SafeArea(
        child: () {
          // 1. Đang khôi phục phiên từ secure storage
          if (authState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Thực sự chưa đăng nhập (session == null)
          if (session == null) {
            return JoyleeEmptyState(
              iconData: Icons.person_outline,
              title: 'Bạn chưa đăng nhập',
              message: 'Vui lòng đăng nhập để chỉnh sửa hồ sơ cá nhân.',
              actionLabel: 'Đăng nhập',
              onAction: () => context.push(
                '${AppPaths.signIn}?from=${AppPaths.editProfile}',
              ),
            );
          }

          // 3. Đã đăng nhập: hiển thị form hồ sơ
          return state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) {
              // Nếu đã có session nhưng tải profile từ backend lỗi, fallback dùng thông tin session
              final fallbackProfile = UserProfile(
                id: session.userId,
                username: session.username,
                role: session.role,
              );
              return _EditProfileForm(profile: fallbackProfile);
            },
            data: (profile) => _EditProfileForm(profile: profile),
          );
        }(),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late final TextEditingController _displayName;
  late final TextEditingController _bio;
  Uint8List? _selectedAvatarBytes;
  String? _selectedAvatarFileName;
  bool _avatarRemoved = false;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(
      text: widget.profile.displayName ?? '',
    );
    _bio = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_isPicking) return;
    final viewModel = ref.read(editProfileViewModelProvider.notifier);
    viewModel.setAvatarError(null);
    setState(() => _isPicking = true);
    try {
      final picked = await ref
          .read(imagePickerServiceProvider)
          .pickFromGallery();
      if (!mounted || picked == null) return;

      final error = validateAvatarSize(picked.bytes.lengthInBytes);
      if (error != null) {
        viewModel.setAvatarError(error);
        return;
      }

      setState(() {
        _selectedAvatarBytes = picked.bytes;
        _selectedAvatarFileName = picked.fileName;
        _avatarRemoved = false;
      });
    } on AppException catch (e) {
      if (mounted) viewModel.setAvatarError(e.message);
    } catch (_) {
      if (mounted) {
        viewModel.setAvatarError('Không thể chọn ảnh. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removeAvatar() {
    ref.read(editProfileViewModelProvider.notifier).setAvatarError(null);
    setState(() {
      _selectedAvatarBytes = null;
      _selectedAvatarFileName = null;
      _avatarRemoved = true;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(editProfileViewModelProvider.notifier)
        .submit(
          displayName: _displayName.text,
          bio: _bio.text,
          currentAvatarUrl: widget.profile.avatarUrl,
          newAvatarBytes: _selectedAvatarBytes,
          newAvatarFileName: _selectedAvatarFileName,
          removeAvatar: _avatarRemoved,
        );
    if (!success || !mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ.')));

    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppPaths.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileViewModelProvider);
    ref.listen(editProfileViewModelProvider.select((s) => s.errorMessage), (
      _,
      message,
    ) {
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    });

    final colors = context.colors;
    final existingAvatarUrl = widget.profile.avatarUrl?.trim();
    final hasExistingAvatar =
        !_avatarRemoved &&
        existingAvatarUrl != null &&
        existingAvatarUrl.isNotEmpty;
    final showRemoveAvatar = _selectedAvatarBytes != null || hasExistingAvatar;
    final canInteract = !state.isLoading && !_isPicking && !state.isSuccess;

    return PopScope(
      canPop: !state.isLoading && !_isPicking,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.space6,
          AppDimensions.space4,
          AppDimensions.space6,
          AppDimensions.space8,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedBuilder(
                  animation: _displayName,
                  builder: (context, _) {
                    final name = _displayName.text.trim().isEmpty
                        ? widget.profile.username
                        : _displayName.text.trim();
                    return Center(
                      child: JoyleeAvatar(
                        initials: name.isEmpty
                            ? '?'
                            : name.substring(0, 1).toUpperCase(),
                        imageUrl: hasExistingAvatar ? existingAvatarUrl : null,
                        imageBytes: _selectedAvatarBytes,
                        size: JoyleeAvatarSize.xl,
                        semanticLabel: 'Ảnh đại diện xem trước',
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.space2),
                Text(
                  '@${widget.profile.username}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.space4),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppDimensions.space2,
                  runSpacing: AppDimensions.space2,
                  children: [
                    JoyleeButton(
                      label: 'Chọn ảnh',
                      variant: JoyleeButtonVariant.secondary,
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      isFullWidth: false,
                      isLoading: _isPicking,
                      onPressed: canInteract ? _pickAvatar : null,
                    ),
                    if (showRemoveAvatar)
                      TextButton.icon(
                        onPressed: canInteract ? _removeAvatar : null,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Xóa ảnh'),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.danger,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space2),
                Text(
                  'JPG, PNG hoặc WEBP. Tối đa 2MB. '
                  'Ảnh mới được tải lên khi bạn bấm Lưu thay đổi.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.textSecondary),
                ),
                if (state.avatarError != null) ...[
                  const SizedBox(height: AppDimensions.space2),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      state.avatarError!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.danger),
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.space6),
                JoyleeTextField(
                  label: 'Tên hiển thị',
                  controller: _displayName,
                  helperText:
                      'Tối đa 64 ký tự. Để trống để dùng tên đăng nhập.',
                  errorText: state.displayNameError,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppDimensions.space4),
                JoyleeTextField(
                  label: 'Giới thiệu',
                  controller: _bio,
                  helperText: 'Tối đa 500 ký tự.',
                  errorText: state.bioError,
                  keyboardType: TextInputType.multiline,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: AppDimensions.space6),
                JoyleeButton(
                  label: 'Lưu thay đổi',
                  isLoading: state.isLoading,
                  onPressed: state.isLoading || _isPicking || state.isSuccess
                      ? null
                      : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
