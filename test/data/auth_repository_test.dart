import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/config/api_endpoints.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/data/services/auth_interceptor.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';

import '../../testing/fakes/fake_token_storage.dart';

/// Tạo JWT giả với claims giống backend .NET (tên/role dùng URI dài)
String _fakeJwt({DateTime? expiresAt}) {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final payload = part({
    'sub': 'user-1',
    'unique_name': 'phuc123',
    'http://schemas.microsoft.com/ws/2008/06/identity/claims/role': 'Author',
    if (expiresAt != null) 'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
  });
  return '${part({'alg': 'HS256'})}.$payload.signature';
}

class _FakeServer implements HttpClientAdapter {
  _FakeServer(this.statusCode, {this.withRefreshToken = true});
  final int statusCode;
  RequestOptions? lastRequest;
  int requestCount = 0;

  /// false = giống bản backend đang deploy (chưa trả refreshToken)
  final bool withRefreshToken;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    requestCount++;
    final body = options.path == ApiEndpoints.authChangePassword
        ? <String, dynamic>{'message': 'Current password is incorrect.'}
        : (options.path == ApiEndpoints.authSignOut ||
              options.path == ApiEndpoints.authForgotPassword)
        ? <String, dynamic>{'message': 'OK'}
        : {
            'accessToken': _fakeJwt(),
            'tokenType': 'Bearer',
            if (withRefreshToken) 'refreshToken': 'refresh-1',
          };
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

AuthRepository _buildRepository(
  FakeTokenStorage storage,
  int statusCode, {
  bool withRefreshToken = true,
}) {
  final dio =
      createApiClient(
          storage,
          Uri.parse('https://gateway.test'),
          onSessionExpired: () {},
        )
        ..httpClientAdapter = _FakeServer(
          statusCode,
          withRefreshToken: withRefreshToken,
        );
  return AuthRepository(dio, storage);
}

void main() {
  test(
    'Google gửi đúng ID token qua gateway, bỏ refresh và lưu phiên',
    () async {
      final storage = FakeTokenStorage();
      final server = _FakeServer(200);
      final dio = createApiClient(
        storage,
        Uri.parse('https://gateway.test'),
        onSessionExpired: () {},
      )..httpClientAdapter = server;
      final session = await AuthRepository(
        dio,
        storage,
      ).signInWithGoogle(idToken: 'google-id');
      expect(server.lastRequest!.method, 'POST');
      expect(server.lastRequest!.path, ApiEndpoints.authGoogle);
      expect(server.lastRequest!.data, {'idToken': 'google-id'});
      expect(
        server.lastRequest!.extra[AuthInterceptor.skipAuthRefresh],
        isTrue,
      );
      expect(session.userId, 'user-1');
      expect(storage.accessToken, _fakeJwt());
      expect(storage.refreshToken, 'refresh-1');
    },
  );

  test('Google 401 không refresh hoặc xóa phiên cũ', () async {
    final storage = FakeTokenStorage(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    final server = _FakeServer(401);
    var expired = false;
    final dio = createApiClient(
      storage,
      Uri.parse('https://gateway.test'),
      onSessionExpired: () => expired = true,
    )..httpClientAdapter = server;
    await expectLater(
      AuthRepository(dio, storage).signInWithGoogle(idToken: 'invalid'),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'Không thể xác minh tài khoản Google. Vui lòng đăng nhập lại.',
        ),
      ),
    );
    expect(server.requestCount, 1);
    expect(expired, isFalse);
    expect(storage.accessToken, 'old-access');
    expect(storage.refreshToken, 'old-refresh');
  });

  test('Google không nhận token rỗng hoặc quá dài', () async {
    final storage = FakeTokenStorage();
    final server = _FakeServer(200);
    final dio = Dio()..httpClientAdapter = server;
    for (final token in ['', '   ', 'a' * 4097]) {
      await expectLater(
        AuthRepository(dio, storage).signInWithGoogle(idToken: token),
        throwsA(isA<AppException>()),
      );
    }
    expect(server.requestCount, 0);
    expect(storage.accessToken, isNull);
  });

  test('Google 503 trả thông báo thân thiện và không lưu token', () async {
    final storage = FakeTokenStorage();
    await expectLater(
      _buildRepository(storage, 503).signInWithGoogle(idToken: 'google-id'),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'Đăng nhập Google tạm thời không khả dụng. Vui lòng thử lại sau.',
        ),
      ),
    );
    expect(storage.accessToken, isNull);
  });

  test('Google phản hồi thiếu accessToken không lưu phiên', () async {
    final storage = FakeTokenStorage();
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: <String, dynamic>{'refreshToken': 'r'},
                statusCode: 200,
              ),
            );
          },
        ),
      );
    await expectLater(
      AuthRepository(dio, storage).signInWithGoogle(idToken: 'google-id'),
      throwsA(isA<AppException>()),
    );
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });

  test(
    'Đổi mật khẩu gửi PUT đúng hợp đồng và xóa cả hai token khi thành công',
    () async {
      final storage = FakeTokenStorage(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
      final server = _FakeServer(204);
      final dio = createApiClient(
        storage,
        Uri.parse('https://gateway.test'),
        onSessionExpired: () {},
      )..httpClientAdapter = server;
      await AuthRepository(dio, storage).changePassword(
        currentPassword: ' oldPassword123 ',
        newPassword: ' newPassword123 ',
        confirmNewPassword: ' newPassword123 ',
      );
      expect(server.lastRequest!.method, 'PUT');
      expect(server.lastRequest!.path, ApiEndpoints.authChangePassword);
      expect(server.lastRequest!.headers['Authorization'], 'Bearer old-access');
      expect(server.lastRequest!.data, {
        'currentPassword': ' oldPassword123 ',
        'newPassword': ' newPassword123 ',
        'confirmNewPassword': ' newPassword123 ',
      });
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    },
  );

  test(
    'Mật khẩu hiện tại sai được dịch sang tiếng Việt và giữ token',
    () async {
      final storage = FakeTokenStorage(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
      await expectLater(
        _buildRepository(storage, 400).changePassword(
          currentPassword: 'wrongPassword1',
          newPassword: 'newPassword123',
          confirmNewPassword: 'newPassword123',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'Mật khẩu hiện tại không đúng.',
          ),
        ),
      );
      expect(storage.accessToken, 'old-access');
      expect(storage.refreshToken, 'old-refresh');
    },
  );

  test('Đăng nhập thành công: lưu token và đọc thông tin từ JWT', () async {
    final storage = FakeTokenStorage();
    final session = await _buildRepository(
      storage,
      200,
    ).signIn(username: 'phuc123', password: 'matkhau123');

    expect(session.userId, 'user-1');
    expect(session.username, 'phuc123');
    expect(session.role, UserRole.author);
    expect(storage.refreshToken, 'refresh-1');
  });

  test('Sai mật khẩu (401) đổi thành thông báo tiếng Việt', () async {
    final storage = FakeTokenStorage();
    await expectLater(
      _buildRepository(
        storage,
        401,
      ).signIn(username: 'phuc123', password: 'saimatkhau1'),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'Tên đăng nhập hoặc mật khẩu không đúng.',
        ),
      ),
    );
    expect(storage.accessToken, isNull);
  });

  test('Đăng xuất luôn xóa token kể cả khi máy chủ báo lỗi', () async {
    final storage = FakeTokenStorage(accessToken: 'a', refreshToken: 'r');
    await _buildRepository(storage, 500).signOut();

    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
  });

  test('Khôi phục phiên: không có token thì trả về null', () async {
    final repository = _buildRepository(FakeTokenStorage(), 200);
    expect(await repository.restoreSession(), isNull);
  });

  test('Khôi phục phiên: có token thì đọc lại thông tin người dùng', () async {
    final storage = FakeTokenStorage(
      accessToken: _fakeJwt(),
      refreshToken: 'r',
    );
    final session = await _buildRepository(storage, 200).restoreSession();
    expect(session?.username, 'phuc123');
  });

  test('Backend chưa trả refreshToken vẫn đăng nhập được', () async {
    final storage = FakeTokenStorage();
    final session = await _buildRepository(
      storage,
      200,
      withRefreshToken: false,
    ).signIn(username: 'phuc123', password: 'matkhau123');

    expect(session.username, 'phuc123');
    expect(storage.accessToken, isNotNull);
    expect(storage.refreshToken, isNull);
  });

  test(
    'Khôi phục phiên: token hết hạn và không có refresh token thì đăng xuất',
    () async {
      final storage = FakeTokenStorage(
        accessToken: _fakeJwt(
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );
      final session = await _buildRepository(storage, 200).restoreSession();

      expect(session, isNull);
      expect(storage.accessToken, isNull);
    },
  );

  test(
    'Khôi phục phiên: token còn hạn, không có refresh token vẫn giữ phiên',
    () async {
      final storage = FakeTokenStorage(
        accessToken: _fakeJwt(
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        ),
      );
      final session = await _buildRepository(storage, 200).restoreSession();
      expect(session?.username, 'phuc123');
    },
  );

  test('Gửi yêu cầu quên mật khẩu thành công khi máy chủ trả 200', () async {
    final storage = FakeTokenStorage();
    final repo = _buildRepository(storage, 200);

    await expectLater(
      repo.forgotPassword(email: 'user@joyleebook.com'),
      completes,
    );
  });

  test(
    'Gửi yêu cầu quên mật khẩu ném AppException khi máy chủ báo lỗi',
    () async {
      final storage = FakeTokenStorage();
      final repo = _buildRepository(storage, 500);

      await expectLater(
        repo.forgotPassword(email: 'user@joyleebook.com'),
        throwsA(isA<AppException>()),
      );
    },
  );
}
