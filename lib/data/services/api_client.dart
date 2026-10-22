import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/environment.dart';
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

final apiClientProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(gatewayBaseUrlProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return createApiClient(tokenStorage, Environment.parseUri(baseUrl));
});

Dio createApiClient(TokenStorage tokenStorage, Uri baseUri) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUri.toString(),
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 10),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException err, handler) async {
        // Tự động thu hồi token lưu cục bộ khi phiên hết hạn hoặc không hợp lệ (401)
        if (err.response?.statusCode == 401) {
          await tokenStorage.clear();
        }
        handler.next(err);
      },
    ),
  );

  return dio;
}
