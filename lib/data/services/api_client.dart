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
        // final token = await tokenStorage.read();
        final token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI3OGIzOGRkMi1iMzE5LTQyYTEtODgwNS0xYWUyODZiMzhhNWIiLCJodHRwOi8vc2NoZW1hcy54bWxzb2FwLm9yZy93cy8yMDA1LzA1L2lkZW50aXR5L2NsYWltcy9uYW1laWRlbnRpZmllciI6Ijc4YjM4ZGQyLWIzMTktNDJhMS04ODA1LTFhZTI4NmIzOGE1YiIsInVuaXF1ZV9uYW1lIjoicGh1YyIsImh0dHA6Ly9zY2hlbWFzLnhtbHNvYXAub3JnL3dzLzIwMDUvMDUvaWRlbnRpdHkvY2xhaW1zL25hbWUiOiJwaHVjIiwiaHR0cDovL3NjaGVtYXMubWljcm9zb2Z0LmNvbS93cy8yMDA4LzA2L2lkZW50aXR5L2NsYWltcy9yb2xlIjoiUmVhZGVyIiwianRpIjoiZmQyMjgyYzMtMzQ2YS00NDVjLWI3NzUtNDYxYzc3YjdkY2I1IiwibmJmIjoxNzkyMzIyNzQzLCJleHAiOjE3OTIzMjQ1NDMsImlzcyI6IkpveWxlZUJvb2suQXV0aGVudGljYXRpb24iLCJhdWQiOiJKb3lsZWVCb29rLkFwaSJ9.212dIrzawXEf7UwJpPCvKjyU-SMWUderwpmKFv9JbTg";
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
}
