import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
import 'package:joyleebook_mobile/ui/auth/view_models/auth_session_view_model.dart';

final profileViewModelProvider =
    AsyncNotifierProvider<ProfileViewModel, UserProfile>(
      ProfileViewModel.new,
      // Riverpod 3 mặc định tự thử lại khi build() lỗi (tối đa 10 lần).
      // Tắt đi: lỗi 401 thử lại cũng vô ích, và màn hình đã có nút "Thử lại".
      retry: (retryCount, error) => null,
    );

class ProfileViewModel extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    // Theo dõi phiên: đăng nhập / đăng xuất thì hồ sơ tự tải lại
    final session = await ref.watch(authSessionProvider.future);
    if (session == null) {
      throw const AppException(message: 'Bạn chưa đăng nhập.', statusCode: 401);
    }
    return repository.getMyProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getMyProfile(),
    );
  }
}
