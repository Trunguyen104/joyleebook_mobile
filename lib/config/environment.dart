import 'package:flutter/foundation.dart';

abstract final class Environment {
  /// Base URL được truyền qua `--dart-define=API_BASE_URL` lúc build
  static const String definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// URL mặc định thông minh theo từng nền tảng chạy
  static String get defaultBaseUrl {
    if (definedBaseUrl.isNotEmpty) {
      return definedBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:5081';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator chuẩn dùng 10.0.2.2 để gọi tới localhost của máy host
        return 'http://10.0.2.2:5081';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:5081';
    }
  }

  static Uri parseUri(String url) {
    var cleaned = url.trim();
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    return Uri.parse(cleaned);
  }
}
