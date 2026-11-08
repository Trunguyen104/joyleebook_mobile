import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/config/api_endpoints.dart';
import 'package:joyleebook_mobile/data/repositories/media_repository.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';

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

MediaRepository _buildRepository(_FakeServer server) {
  final storage = FakeTokenStorage(accessToken: 'access-1');
  final dio = createApiClient(
    storage,
    Uri.parse('https://gateway.test'),
    onSessionExpired: () {},
  )..httpClientAdapter = server;
  return MediaRepository(dio);
}

void main() {
  test('Upload avatar gửi multipart đúng field File và parse URL', () async {
    final server = _FakeServer(200, {
      'url': 'https://res.cloudinary.com/demo/avatar.png',
      'publicId': 'joyleebook/avatars/user-1',
    });
    final repository = _buildRepository(server);

    final url = await repository.uploadAvatar(
      bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
      fileName: 'avatar.png',
    );

    expect(server.lastRequest!.method, 'POST');
    expect(server.lastRequest!.path, ApiEndpoints.mediaUploadAvatar);
    expect(server.lastRequest!.headers['Authorization'], 'Bearer access-1');
    expect(
      server.lastRequest!.headers[Headers.contentTypeHeader]?.toString(),
      contains(Headers.multipartFormDataContentType),
    );

    final form = server.lastRequest!.data as FormData;
    expect(form.files.single.key, 'File');
    expect(form.files.single.value.filename, 'avatar.png');
    expect(url, 'https://res.cloudinary.com/demo/avatar.png');
  });

  test('Lỗi FileTooLarge được map sang thông báo dung lượng', () async {
    final server = _FakeServer(400, {
      'title': 'Validation Error',
      'detail': 'Dung lượng ảnh vượt quá giới hạn cho phép (2MB).',
      'errorCode': 'Media.FileTooLarge',
    });
    final repository = _buildRepository(server);

    await expectLater(
      repository.uploadAvatar(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.jpg',
      ),
      throwsA(
        isA<AppException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', contains('2MB')),
      ),
    );
  });

  test('Lỗi NotConfigured được map sang thông báo cấu hình', () async {
    final server = _FakeServer(503, {
      'title': 'Service Unavailable',
      'detail': 'Dịch vụ lưu trữ ảnh chưa được cấu hình.',
      'errorCode': 'Media.NotConfigured',
    });
    final repository = _buildRepository(server);

    await expectLater(
      repository.uploadAvatar(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.jpg',
      ),
      throwsA(
        isA<AppException>()
            .having((e) => e.statusCode, 'statusCode', 503)
            .having(
              (e) => e.message,
              'message',
              contains('chưa được cấu hình'),
            ),
      ),
    );
  });

  test('Gateway 502 báo dịch vụ ảnh chưa bật', () async {
    final server = _FakeServer(502, {});
    final repository = _buildRepository(server);

    await expectLater(
      repository.uploadAvatar(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.jpg',
      ),
      throwsA(
        isA<AppException>()
            .having((e) => e.statusCode, 'statusCode', 502)
            .having((e) => e.message, 'message', contains('HTTP 502')),
      ),
    );
  });

  test('Response thiếu URL báo lỗi thân thiện', () async {
    final server = _FakeServer(200, {'publicId': 'user-1'});
    final repository = _buildRepository(server);

    await expectLater(
      repository.uploadAvatar(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.jpg',
      ),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('không trả về đường dẫn'),
        ),
      ),
    );
  });
}
