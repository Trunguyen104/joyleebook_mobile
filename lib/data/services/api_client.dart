import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/environment.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

class GatewayBaseUrlNotifier extends Notifier<String> {
  @override
  String build() => Environment.defaultBaseUrl;

  void setUrl(String url) => state = url;
}

final gatewayBaseUrlProvider = NotifierProvider<GatewayBaseUrlNotifier, String>(
  GatewayBaseUrlNotifier.new,
);

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  // TokenStorage dùng flutter_secure_storage
  const storage = FlutterSecureStorage();
  return TokenStorage(storage);
});

/// Cờ "phiên đăng nhập đã hết hạn" (_isSessionExpiredHandled trong docs/03).
/// Chỉ đổi false -> true một lần, nên dù 5 request cùng lỗi 401
/// thì người dùng cũng chỉ thấy 1 thông báo.
class SessionExpiredNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markExpired() {
    if (!state) state = true;
  }

  /// Gọi lại khi người dùng đăng nhập thành công
  void reset() => state = false;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, bool>(
  SessionExpiredNotifier.new,
);

final apiClientProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(gatewayBaseUrlProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return createApiClient(
    tokenStorage,
    Environment.parseUri(baseUrl),
    // ref.read chạy lúc phiên hết hạn, không phải lúc build provider
    onSessionExpired: () =>
        ref.read(sessionExpiredProvider.notifier).markExpired(),
  );
});

Dio createApiClient(
  TokenStorage tokenStorage,
  Uri baseUri, {
  required void Function() onSessionExpired,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUri.toString(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenStorage: tokenStorage,
      onSessionExpired: onSessionExpired,
    ),
  );

  return dio;
}
