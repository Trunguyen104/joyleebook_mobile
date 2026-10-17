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
      // validateStatus: (status) => status != null && status < 500,
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
    ),
  );

  return dio;
}
