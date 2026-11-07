import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/services/search_utils.dart';

void main() {
  group('SearchUtils - Tìm kiếm tiếng Việt thông minh', () {
    const title = 'Hồi Ức Người Lữ Khách';
    const author = 'Tác giả JoyleeBook';

    test('So khớp chính xác có dấu thường và hoa', () {
      expect(SearchUtils.matches(title, 'Hồi ức'), isTrue);
      expect(SearchUtils.matches(title, 'hồi ức'), isTrue);
      expect(SearchUtils.matches(title, 'HỒI ỨC'), isTrue);
      expect(SearchUtils.matches(title, 'Lữ Khách'), isTrue);
    });

    test(
      'So khớp khi người dùng gõ thêm dấu ba chấm hoặc khoảng trắng thừa',
      () {
        expect(SearchUtils.matches(title, 'Hồi ức ...'), isTrue);
        expect(SearchUtils.matches(title, 'Hồi ức...'), isTrue);
        expect(SearchUtils.matches(title, '   Hồi ức   '), isTrue);
        expect(SearchUtils.matches(title, 'lữ khách...'), isTrue);
      },
    );

    test('So khớp tiếng Việt không dấu (Accent-insensitive)', () {
      expect(SearchUtils.matches(title, 'hoi uc'), isTrue);
      expect(SearchUtils.matches(title, 'Hoi uc'), isTrue);
      expect(SearchUtils.matches(title, 'lu khach'), isTrue);
      expect(SearchUtils.matches(title, 'nguoi lu khach'), isTrue);
    });

    test('So khớp bảng mã Unicode tổ hợp (NFD) gõ từ iOS/macOS', () {
      // 'H' + 'o' + '\u0302' + '\u0300' + 'i'
      const nfdQuery = 'Ho\u0302\u0300i u\u031B\u0301c';
      expect(SearchUtils.matches(title, nfdQuery), isTrue);
    });

    test('So khớp đa từ (Multi-word) không phân biệt thứ tự', () {
      expect(SearchUtils.matches(title, 'lữ khách hồi ức'), isTrue);
      expect(SearchUtils.matches(title, 'hồi khách'), isTrue);
      expect(SearchUtils.matches(title, 'người hồi ức'), isTrue);
    });

    test('So khớp tên tác giả', () {
      expect(SearchUtils.matches(author, 'JoyleeBook'), isTrue);
      expect(SearchUtils.matches(author, 'joylee'), isTrue);
      expect(SearchUtils.matches(author, 'tac gia'), isTrue);
    });

    test('Từ khóa rỗng hoặc dấu chấm đơn lẻ luôn trả về true', () {
      expect(SearchUtils.matches(title, ''), isTrue);
      expect(SearchUtils.matches(title, '   '), isTrue);
      expect(SearchUtils.matches(title, '...'), isTrue);
      expect(SearchUtils.matches(title, null), isTrue);
    });

    test('Từ khóa không liên quan trả về false', () {
      expect(SearchUtils.matches(title, 'tam quoc'), isFalse);
      expect(SearchUtils.matches(title, 'doremon'), isFalse);
    });
  });
}
