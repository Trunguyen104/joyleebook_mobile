import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/config/api_endpoints.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
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

  /// false = giống bản backend đang deploy (chưa trả refreshToken)
  final bool withRefreshToken;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = options.path == ApiEndpoints.authSignOut
        ? <String, dynamic>{}
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
}
