import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/media_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/services/api_exceptions.dart';
import 'profile_validators.dart';
import 'profile_view_model.dart';

@immutable
class EditProfileState {
  const EditProfileState({
    this.isLoading = false,
    this.isSuccess = false,
    this.displayNameError,
    this.bioError,
    this.avatarError,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? displayNameError;
  final String? bioError;
  final String? avatarError;

  /// Lỗi chung từ máy chủ (mất mạng, hết phiên...) -> hiện SnackBar
  final String? errorMessage;
}

final editProfileViewModelProvider =
    NotifierProvider.autoDispose<EditProfileViewModel, EditProfileState>(
      EditProfileViewModel.new,
    );

class EditProfileViewModel extends Notifier<EditProfileState> {
  @override
  EditProfileState build() => const EditProfileState();

  void setAvatarError(String? message) {
    state = EditProfileState(
      isLoading: state.isLoading,
      isSuccess: state.isSuccess,
      displayNameError: state.displayNameError,
      bioError: state.bioError,
      avatarError: message,
      errorMessage: state.errorMessage,
    );
  }

  Future<bool> submit({
    required String displayName,
    required String bio,
    required String? currentAvatarUrl,
    Uint8List? newAvatarBytes,
    String? newAvatarFileName,
    bool removeAvatar = false,
  }) async {
    if (state.isLoading || state.isSuccess) return false;

    final trimmedDisplayName = displayName.trim();
    final trimmedBio = bio.trim();

    final displayNameError = validateDisplayName(trimmedDisplayName);
    final bioError = validateBio(trimmedBio);
    final avatarError = newAvatarBytes == null
        ? null
        : validateAvatarSize(newAvatarBytes.lengthInBytes);
    final fileNameError =
        newAvatarBytes != null &&
            (newAvatarFileName == null || newAvatarFileName.trim().isEmpty)
        ? 'Ảnh đã chọn không hợp lệ.'
        : null;
    final effectiveAvatarError = avatarError ?? fileNameError;

    if (displayNameError != null ||
        bioError != null ||
        effectiveAvatarError != null) {
      state = EditProfileState(
        displayNameError: displayNameError,
        bioError: bioError,
        avatarError: effectiveAvatarError,
      );
      return false;
    }

    state = const EditProfileState(isLoading: true);
    final profileNotifier = ref.read(profileViewModelProvider.notifier);

    final trimmedCurrentAvatar = currentAvatarUrl?.trim();
    var avatarUrl =
        removeAvatar ||
            trimmedCurrentAvatar == null ||
            trimmedCurrentAvatar.isEmpty
        ? null
        : trimmedCurrentAvatar;

    if (newAvatarBytes != null) {
      try {
        avatarUrl = await ref
            .read(mediaRepositoryProvider)
            .uploadAvatar(bytes: newAvatarBytes, fileName: newAvatarFileName!);
      } on AppException catch (e) {
        if (ref.mounted) state = EditProfileState(avatarError: e.message);
        return false;
      } catch (_) {
        if (ref.mounted) {
          state = const EditProfileState(
            avatarError: 'Không thể tải ảnh lên. Vui lòng thử lại.',
          );
        }
        return false;
      }
    }

    try {
      final updated = await ref
          .read(profileRepositoryProvider)
          .updateMyProfile(
            displayName: trimmedDisplayName.isEmpty ? null : trimmedDisplayName,
            bio: trimmedBio.isEmpty ? null : trimmedBio,
            avatarUrl: avatarUrl,
          );
      profileNotifier.applyUpdatedProfile(updated);
      if (ref.mounted) state = const EditProfileState(isSuccess: true);
      return true;
    } on AppException catch (e) {
      if (!ref.mounted) return false;
      final fieldErrors = e.fieldErrors;
      final displayNameFieldError = fieldErrors?['displayname'];
      final bioFieldError = fieldErrors?['bio'];
      final avatarFieldError = fieldErrors?['avatarurl'];
      final hasFieldError =
          displayNameFieldError != null ||
          bioFieldError != null ||
          avatarFieldError != null;
      state = EditProfileState(
        displayNameError: displayNameFieldError,
        bioError: bioFieldError,
        avatarError: avatarFieldError,
        errorMessage: hasFieldError ? null : e.message,
      );
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = const EditProfileState(
          errorMessage: 'Không thể cập nhật hồ sơ. Vui lòng thử lại.',
        );
      }
      return false;
    }
  }
}
