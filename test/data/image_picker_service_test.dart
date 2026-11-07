import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/services/image_picker_service.dart';

void main() {
  group('detectAvatarExtension', () {
    test('Nhận diện JPEG', () {
      expect(
        detectAvatarExtension(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])),
        'jpg',
      );
    });

    test('Nhận diện PNG', () {
      expect(
        detectAvatarExtension(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        ),
        'png',
      );
    });

    test('Nhận diện WEBP', () {
      final bytes = Uint8List.fromList([
        0x52,
        0x49,
        0x46,
        0x46,
        0x00,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
        0x50,
      ]);
      expect(detectAvatarExtension(bytes), 'webp');
    });

    test('Từ chối định dạng khác', () {
      expect(detectAvatarExtension(Uint8List.fromList([1, 2, 3])), isNull);
      expect(detectAvatarExtension(Uint8List(0)), isNull);
      expect(
        detectAvatarExtension(Uint8List.fromList([0x47, 0x49, 0x46, 0x38])),
        isNull,
      );
    });
  });
}
