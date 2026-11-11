import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/data/services/google_sign_in_service.dart';

/// Không mở SDK Google hoặc gọi mạng trong kiểm thử.
class FakeGoogleSignInService implements GoogleSignInService {
  FakeGoogleSignInService({this.idToken = 'google-id-token', this.error});

  final String? idToken;
  final AppException? error;
  int callCount = 0;

  @override
  Future<String?> authenticate() async {
    callCount++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error!;
    return idToken;
  }
}
