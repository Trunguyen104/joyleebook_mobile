import 'dart:typed_data';

import 'package:joyleebook_mobile/data/repositories/media_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';

class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository({
    this.uploadedUrl = 'https://res.cloudinary.com/demo/avatar.jpg',
    this.error,
    this.delay,
  });

  String uploadedUrl;
  AppException? error;
  Duration? delay;
  int uploadCallCount = 0;
  Uint8List? lastBytes;
  String? lastFileName;

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    uploadCallCount++;
    lastBytes = bytes;
    lastFileName = fileName;
    if (delay != null) await Future<void>.delayed(delay!);
    if (error != null) throw error!;
    return uploadedUrl;
  }
}
