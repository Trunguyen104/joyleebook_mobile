import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';

/// Repository giả cho test: không gọi mạng, trả dữ liệu hoặc lỗi định sẵn
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.profile, this.error});

  UserProfile? profile;
  AppException? error;
  int callCount = 0; // đếm số lần gọi để kiểm tra nút "Thử lại"

  @override
  Future<UserProfile> getMyProfile() async {
    callCount++;
    // Trễ nhẹ để test nhìn thấy được trạng thái loading
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
    return profile!;
  }
}
