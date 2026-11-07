import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/config/api_endpoints.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/auth_interceptor.dart';

import '../../testing/fakes/fake_token_storage.dart';

/// "Máy chủ" giả: chỉ chấp nhận access token mới, đếm số lần gọi /refresh
class _FakeServer implements HttpClientAdapter {
  int refreshCalls = 0;
  bool refreshFails = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (options.path == ApiEndpoints.authRefresh) {
      refreshCalls++;
      if (refreshFails) return _json(401, {'message': 'expired'});
      return _json(200, {
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
      });
    }
    final authorized = options.headers['Authorization'] == 'Bearer new-access';
    return authorized ? _json(200, {'ok': true}) : _json(401, {});
  }

  ResponseBody _json(int status, Map<String, dynamic> body) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeTokenStorage storage;
  late _FakeServer server;
  late Dio dio;
  late int expiredCalls;

  setUp(() {
    storage = FakeTokenStorage(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    server = _FakeServer();
    expiredCalls = 0;
    dio = createApiClient(
      storage,
      Uri.parse('https://gateway.test'),
      onSessionExpired: () => expiredCalls++,
    )..httpClientAdapter = server;
  });

  test(
    '3 request cùng bị 401 chỉ gọi refresh 1 lần rồi gửi lại cả 3',
    () async {
      final responses = await Future.wait([
        dio.get<dynamic>('/api/profiles/me'),
        dio.get<dynamic>('/api/library/stats'),
        dio.get<dynamic>('/api/library'),
      ]);

      expect(server.refreshCalls, 1);
      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(storage.accessToken, 'new-access');
      expect(storage.refreshToken, 'new-refresh');
      expect(expiredCalls, 0);
    },
  );

  test(
    'Upload multipart gặp 401 vẫn retry được sau khi refresh token',
    () async {
      final response = await dio.post<dynamic>(
        ApiEndpoints.mediaUploadAvatar,
        data: FormData.fromMap({
          'File': MultipartFile.fromBytes([1, 2, 3], filename: 'avatar.png'),
        }),
      );

      expect(response.statusCode, 200);
      expect(server.refreshCalls, 1);
      expect(storage.accessToken, 'new-access');
    },
  );

  test(
    'Refresh bị từ chối thì xóa token và báo hết phiên đúng 1 lần',
    () async {
      server.refreshFails = true;

      final results = await Future.wait([
        dio
            .get<dynamic>('/api/profiles/me')
            .then<Object?>((r) => r, onError: (Object e) => e),
        dio
            .get<dynamic>('/api/library')
            .then<Object?>((r) => r, onError: (Object e) => e),
      ]);

      expect(results, everyElement(isA<DioException>()));
      expect(server.refreshCalls, 1);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(expiredCalls, 1);
    },
  );

  test('401 của request đăng nhập không kích hoạt refresh', () async {
    await expectLater(
      dio.post<dynamic>(
        ApiEndpoints.authSignIn,
        options: Options(extra: {AuthInterceptor.skipAuthRefresh: true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(server.refreshCalls, 0);
    expect(storage.refreshToken, 'old-refresh');
  });

  test(
    'Chưa đăng nhập (không có token) thì 401 trả thẳng về, không refresh',
    () async {
      await storage.clear();

      await expectLater(
        dio.get<dynamic>('/api/profiles/me'),
        throwsA(isA<DioException>()),
      );
      expect(server.refreshCalls, 0);
      expect(expiredCalls, 0);
    },
  );

  test('Không có refresh token (backend cũ) thì 401 báo hết phiên luôn, không gọi refresh', () async {
    storage.refreshToken = null;

    await expectLater(
      dio.get<dynamic>('/api/profiles/me'),
      throwsA(isA<DioException>()),
    );
    expect(server.refreshCalls, 0);
    expect(storage.accessToken, isNull);
    expect(expiredCalls, 1);
  });
}
