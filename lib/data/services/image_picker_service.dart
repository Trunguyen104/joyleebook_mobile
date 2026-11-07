import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'api_exceptions.dart';

class PickedAvatar {
  const PickedAvatar({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

String? detectAvatarExtension(Uint8List bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return 'jpg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return 'png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }
  return null;
}

class ImagePickerService {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<PickedAvatar?> pickFromGallery() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file == null) return null;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const AppException(message: 'Ảnh đã chọn không hợp lệ.');
      }

      final extension = detectAvatarExtension(bytes);
      if (extension == null) {
        throw const AppException(
          message: 'Chỉ hỗ trợ ảnh JPG, JPEG, PNG hoặc WEBP.',
        );
      }

      return PickedAvatar(bytes: bytes, fileName: 'avatar.$extension');
    } on AppException {
      rethrow;
    } on PlatformException catch (e) {
      throw AppException(message: _messageFor(e));
    } catch (_) {
      throw const AppException(
        message: 'Không thể đọc ảnh đã chọn. Vui lòng chọn ảnh khác.',
      );
    }
  }

  String _messageFor(PlatformException error) {
    return switch (error.code) {
      'photo_access_denied' =>
        'Bạn cần cấp quyền truy cập thư viện ảnh để chọn ảnh đại diện.',
      'camera_access_denied' =>
        'Bạn cần cấp quyền truy cập camera để chụp ảnh đại diện.',
      'invalid_image' => 'Không thể đọc ảnh đã chọn. Vui lòng chọn ảnh khác.',
      'already_active' => 'Trình chọn ảnh đang mở. Vui lòng thử lại.',
      _ => 'Không thể chọn ảnh. Vui lòng thử lại.',
    };
  }
}

final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => ImagePickerService(),
);
