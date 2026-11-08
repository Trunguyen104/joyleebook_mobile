import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/ui/profile/view_models/profile_validators.dart';

void main() {
  group('validateDisplayName', () {
    test('Được để trống và tối đa 64 ký tự', () {
      expect(validateDisplayName(''), isNull);
      expect(validateDisplayName('   '), isNull);
      expect(validateDisplayName('a' * 64), isNull);
      expect(validateDisplayName('${'a' * 64}b'), isNotNull);
    });
  });

  group('validateBio', () {
    test('Được để trống và tối đa 500 ký tự', () {
      expect(validateBio(''), isNull);
      expect(validateBio('a' * 500), isNull);
      expect(validateBio('${'a' * 500}b'), isNotNull);
    });
  });

  group('validateAvatarSize', () {
    test('Chấp nhận ảnh có dữ liệu và không vượt quá 2MB', () {
      expect(validateAvatarSize(1), isNull);
      expect(validateAvatarSize(maxAvatarSizeBytes), isNull);
    });

    test('Từ chối ảnh rỗng hoặc vượt quá 2MB', () {
      expect(validateAvatarSize(0), isNotNull);
      expect(validateAvatarSize(-1), isNotNull);
      expect(validateAvatarSize(maxAvatarSizeBytes + 1), isNotNull);
    });
  });
}
