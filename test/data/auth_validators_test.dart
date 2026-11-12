import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/ui/auth/view_models/auth_validators.dart';

void main() {
  group('validateUsername', () {
    test('Độ dài biên: 2 và 65 ký tự bị từ chối, 3 và 64 hợp lệ', () {
      expect(validateUsername('ab'), isNotNull);
      expect(validateUsername('abc'), isNull);
      expect(validateUsername('a' * 64), isNull);
      expect(validateUsername('a' * 65), isNotNull);
    });

    test('Chỉ nhận chữ, số và . _ -', () {
      expect(validateUsername('phuc.reader_01-x'), isNull);
      expect(validateUsername('phuc nguyen'), isNotNull);
      expect(validateUsername('phuc@mail'), isNotNull);
      expect(validateUsername('phúc'), isNotNull);
    });

    test('Bỏ trống hoặc chỉ có khoảng trắng', () {
      expect(validateUsername(''), 'Vui lòng nhập tên đăng nhập');
      expect(validateUsername('   '), 'Vui lòng nhập tên đăng nhập');
    });
  });

  group('validatePassword', () {
    test('Cần tối thiểu 8 ký tự, có cả chữ và số', () {
      expect(validatePassword('abc1234'), isNotNull); // 7 ký tự
      expect(validatePassword('abcd1234'), isNull);
      expect(validatePassword('abcdefgh'), isNotNull); // thiếu số
      expect(validatePassword('12345678'), isNotNull); // thiếu chữ
    });

    test('Tối đa 128 ký tự', () {
      expect(validatePassword('a1' * 64), isNull);
      expect(validatePassword('${'a1' * 64}x'), isNotNull);
    });
  });

  test('validateConfirmPassword phải trùng khớp 100%', () {
    expect(validateConfirmPassword('abcd1234', 'abcd1234'), isNull);
    expect(
      validateConfirmPassword('abcd1234', 'abcd1235'),
      'Mật khẩu xác nhận không trùng khớp',
    );
    expect(validateConfirmPassword('abcd1234', ''), isNotNull);
  });

  group('validateEmail', () {
    test('Chặn dấu chấm và nhãn tên miền sai, kiểm tra giới hạn độ dài', () {
      for (final email in [
        '.reader@example.com',
        'reader.@example.com',
        'read..er@example.com',
        'reader@-example.com',
        'reader@example-.com',
        '${'a' * 65}@example.com',
        'reader@${'a' * 64}.com',
      ]) {
        expect(validateEmail(email), isNotNull, reason: email);
      }
      expect(validateEmail('${'a' * 64}@example.com'), isNull);
      expect(validateEmail("o'reader@example.com"), isNull);
      expect(validateEmail('reader@${'a' * 63}.com'), isNull);
    });

    test('Bỏ trống hoặc chỉ có khoảng trắng', () {
      expect(validateEmail(''), 'Vui lòng nhập địa chỉ email');
      expect(validateEmail('   '), 'Vui lòng nhập địa chỉ email');
    });

    test('Định dạng email không hợp lệ', () {
      expect(
        validateEmail('plainaddress'),
        'Địa chỉ email không đúng định dạng',
      );
      expect(
        validateEmail('@missingusername.com'),
        'Địa chỉ email không đúng định dạng',
      );
      expect(
        validateEmail('username@.com'),
        'Địa chỉ email không đúng định dạng',
      );
      expect(
        validateEmail('username@com'),
        'Địa chỉ email không đúng định dạng',
      );
      expect(
        validateEmail('user name@example.com'),
        'Địa chỉ email không đúng định dạng',
      );
    });

    test('Định dạng email hợp lệ', () {
      expect(validateEmail('reader@joyleebook.com'), isNull);
      expect(validateEmail('phuc.nguyen+test@gmail.com'), isNull);
      expect(validateEmail('  user123@sub.domain.org  '), isNull);
    });
  });
}
