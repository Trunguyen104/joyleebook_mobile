import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';

/// Repository giả cho test: không gọi mạng, trả dữ liệu hoặc lỗi định sẵn
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({
    this.profile,
    this.error,
    this.updateError,
    this.updateResult,
  });

  UserProfile? profile;
  AppException? error;
  AppException? updateError;
  UserProfile? updateResult;
  int callCount = 0; // đếm số lần gọi để kiểm tra nút "Thử lại"
  int updateCallCount = 0;
  String? lastDisplayName;
  String? lastBio;
  String? lastAvatarUrl;

  @override
  Future<UserProfile> getMyProfile() async {
    callCount++;
    // Trễ nhẹ để test nhìn thấy được trạng thái loading
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
    return profile!;
  }

  @override
  Future<UserProfile> updateMyProfile({
    required String? displayName,
    required String? bio,
    required String? avatarUrl,
  }) async {
    updateCallCount++;
    lastDisplayName = displayName;
    lastBio = bio;
    lastAvatarUrl = avatarUrl;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (updateError != null) throw updateError!;
    if (updateResult != null) return updateResult!;

    final source = profile;
    if (source == null) {
      throw StateError('FakeProfileRepository chưa có hồ sơ để cập nhật');
    }
    return UserProfile(
      id: source.id,
      username: source.username,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
      email: source.email,
      role: source.role,
      stats: source.stats,
    );
  }
}
