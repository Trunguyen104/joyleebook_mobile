import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/data/services/image_picker_service.dart';

class FakeImagePickerService implements ImagePickerService {
  FakeImagePickerService({this.result, this.error, this.delay});

  PickedAvatar? result;
  AppException? error;
  Duration? delay;
  int callCount = 0;

  @override
  Future<PickedAvatar?> pickFromGallery() async {
    callCount++;
    if (delay != null) await Future<void>.delayed(delay!);
    if (error != null) throw error!;
    return result;
  }
}
