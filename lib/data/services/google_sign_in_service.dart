import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../config/environment.dart';
import 'api_exceptions.dart';

/// Chỉ lấy danh tính Google; token phiên JoyleeBook do gateway cấp.
class GoogleSignInService {
  // SDK dùng singleton nên chỉ khởi tạo một lần trong vòng đời ứng dụng.
  static Future<void>? _initialization;

  Future<String?> authenticate() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw const AppException(
        message: 'Đăng nhập Google hiện hỗ trợ ứng dụng Android và iOS.',
      );
    }
    if (Environment.googleServerClientId.isEmpty ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            Environment.googleIosClientId.isEmpty)) {
      throw const AppException(
        message:
            'Đăng nhập Google chưa được cấu hình. Vui lòng liên hệ hỗ trợ.',
      );
    }

    try {
      final google = GoogleSignIn.instance;
      await (_initialization ??= google.initialize(
        serverClientId: Environment.googleServerClientId,
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? Environment.googleIosClientId
            : null,
      ));
      // Cho phép chọn lại tài khoản sau khi đăng xuất hoặc đăng nhập thất bại.
      await google.signOut();
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const AppException(
          message: 'Không thể xác minh tài khoản Google. Vui lòng thử lại.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AppException(
        message: switch (e.code) {
          GoogleSignInExceptionCode.clientConfigurationError ||
          GoogleSignInExceptionCode.providerConfigurationError => 'Đăng nhập Google chưa được cấu hình đúng. Vui lòng liên hệ hỗ trợ.',
          GoogleSignInExceptionCode.interrupted =>
            'Đăng nhập Google bị gián đoạn. Vui lòng thử lại.',
          _ => 'Không thể đăng nhập Google. Vui lòng thử lại.',
        },
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        message: 'Không thể đăng nhập Google. Vui lòng thử lại.',
      );
    }
  }
}

final googleSignInServiceProvider = Provider<GoogleSignInService>(
  (ref) => GoogleSignInService(),
);
