import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/config/api_endpoints.dart';
import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';

import '../../testing/fakes/fake_token_storage.dart';

class _FakeServer implements HttpClientAdapter {
  _FakeServer(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
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

ProfileRepository _buildRepository(
  FakeTokenStorage storage,
  _FakeServer server,
) {
  final dio = createApiClient(
    storage,
    Uri.parse('https://gateway.test'),
    onSessionExpired: () {},
  )..httpClientAdapter = server;
  return ProfileRepository(dio);
}

void main() {
  test('Cập nhật hồ sơ gửi PUT đúng hợp đồng và parse response', () async {
    final storage = FakeTokenStorage(accessToken: 'access-1');
    final server = _FakeServer(200, {
      'id': 'user-1',
      'username': 'phuc123',
      'role': 'Reader',
      'displayName': 'Phúc',
      'bio': 'Mê truyện trinh thám.',
      'avatarUrl': 'https://cdn.example.com/avatar.png',
      'updatedAtUtc': '2026-11-07T10:00:00Z',
    });
    final repository = _buildRepository(storage, server);

    final profile = await repository.updateMyProfile(
      displayName: 'Phúc',
      bio: 'Mê truyện trinh thám.',
      avatarUrl: 'https://cdn.example.com/avatar.png',
    );

    expect(server.lastRequest!.method, 'PUT');
    expect(server.lastRequest!.path, ApiEndpoints.profiles);
    expect(server.lastRequest!.headers['Authorization'], 'Bearer access-1');
    expect(server.lastRequest!.data, {
      'displayName': 'Phúc',
      'bio': 'Mê truyện trinh thám.',
      'avatarUrl': 'https://cdn.example.com/avatar.png',
    });
    expect(profile.id, 'user-1');
    expect(profile.username, 'phuc123');
    expect(profile.name, 'Phúc');
    expect(profile.bio, 'Mê truyện trinh thám.');
    expect(profile.avatarUrl, 'https://cdn.example.com/avatar.png');
    expect(profile.role, UserRole.reader);
    expect(profile.stats.seriesStarted, 0);
  });

  test('Gửi null để xóa các trường hồ sơ', () async {
    final storage = FakeTokenStorage(accessToken: 'access-1');
    final server = _FakeServer(200, {
      'id': 'user-1',
      'username': 'phuc123',
      'role': 'Reader',
      'displayName': null,
      'bio': null,
      'avatarUrl': null,
    });
    final repository = _buildRepository(storage, server);

    await repository.updateMyProfile(
      displayName: null,
      bio: null,
      avatarUrl: null,
    );

    expect(server.lastRequest!.data, {
      'displayName': null,
      'bio': null,
      'avatarUrl': null,
    });
  });

  test('400 ValidationProblemDetails được map về lỗi từng trường', () async {
    final storage = FakeTokenStorage(accessToken: 'access-1');
    final server = _FakeServer(400, {
      'title': 'One or more validation errors occurred.',
      'errors': {
        'DisplayName': [
          'The field DisplayName must be a string with a maximum length of 64.',
        ],
        'Bio': ['The field Bio must be a string with a maximum length of 500.'],
        'AvatarUrl': ['Avatar URL must be an absolute HTTPS URL.'],
      },
    });
    final repository = _buildRepository(storage, server);

    await expectLater(
      repository.updateMyProfile(
        displayName: 'a' * 65,
        bio: 'b' * 501,
        avatarUrl: 'http://example.com/avatar.png',
      ),
      throwsA(
        isA<AppException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having(
              (e) => e.fieldErrors?['displayname'],
              'displayName error',
              'Tên hiển thị tối đa 64 ký tự.',
            )
            .having(
              (e) => e.fieldErrors?['bio'],
              'bio error',
              'Giới thiệu tối đa 500 ký tự.',
            )
            .having(
              (e) => e.fieldErrors?['avatarurl'],
              'avatarUrl error',
              'Ảnh đại diện không hợp lệ. Vui lòng chọn ảnh khác.',
            ),
      ),
    );
  });
}
