import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/dtos/genre_dto.dart';
import 'package:joyleebook_mobile/domain/models/genre.dart';

void main() {
  group('GenreDto & Genre Domain Model - Unit Tests', () {
    test('GenreDto.fromJson trích xuất đầy đủ và an toàn null-safety', () {
      final json = {
        'id': 'g123',
        'name': 'Hành Động',
        'description': 'Truyện hành động mãn nhãn',
        'slug': 'hanh-dong',
        'seriesCount': 15,
      };

      final dto = GenreDto.fromJson(json);

      expect(dto.id, equals('g123'));
      expect(dto.name, equals('Hành Động'));
      expect(dto.description, equals('Truyện hành động mãn nhãn'));
      expect(dto.slug, equals('hanh-dong'));
      expect(dto.seriesCount, equals(15));
    });

    test(
      'GenreDto.fromJson xử lý an toàn khi thiếu trường hoặc giá trị null',
      () {
        final json = <String, dynamic>{
          'id': 456, // id là số nguyên
        };

        final dto = GenreDto.fromJson(json);

        expect(dto.id, equals('456'));
        expect(dto.name, equals('Chưa đặt tên'));
        expect(dto.description, isNull);
        expect(dto.slug, isNull);
        expect(dto.seriesCount, equals(0));
      },
    );

    test('GenreDto.toJson xuất đúng cấu trúc Map', () {
      const dto = GenreDto(
        id: 'g1',
        name: 'Kỳ Ảo',
        description: 'Phép thuật huyền bí',
        seriesCount: 5,
      );

      final map = dto.toJson();

      expect(map['id'], equals('g1'));
      expect(map['name'], equals('Kỳ Ảo'));
      expect(map['description'], equals('Phép thuật huyền bí'));
      expect(map['seriesCount'], equals(5));
    });

    test('Genre.fromDto chuyển đổi chuẩn xác sang Pure Domain Model', () {
      const dto = GenreDto(
        id: 'g2',
        name: '  Trinh Thám  ',
        description: '  Phá án bí ẩn  ',
        seriesCount: 8,
      );

      final model = Genre.fromDto(dto);

      expect(model.id, equals('g2'));
      expect(model.name, equals('Trinh Thám')); // Tự trim khoảng trắng
      expect(model.description, equals('Phá án bí ẩn'));
      expect(model.seriesCount, equals(8));
    });

    test('Genre.copyWith tạo bản sao mới với thuộc tính được thay đổi', () {
      const original = Genre(id: 'g1', name: 'Khoa Huyễn', seriesCount: 3);

      final updated = original.copyWith(
        name: 'Khoa Học Viễn Tưởng',
        seriesCount: 4,
      );

      expect(updated.id, equals('g1'));
      expect(updated.name, equals('Khoa Học Viễn Tưởng'));
      expect(updated.seriesCount, equals(4));
      expect(original.name, equals('Khoa Huyễn')); // Bất biến
    });

    test('Genre so sánh bằng (equality) dựa trên id và name', () {
      const g1 = Genre(id: '1', name: 'Võ Hiệp');
      const g2 = Genre(id: '1', name: 'Võ Hiệp');
      const g3 = Genre(id: '2', name: 'Võ Hiệp');

      expect(g1, equals(g2));
      expect(g1 == g3, isFalse);
    });
  });
}
