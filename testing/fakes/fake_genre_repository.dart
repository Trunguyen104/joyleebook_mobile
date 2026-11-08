import 'package:joyleebook_mobile/data/repositories/genre_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/genre.dart';

/// FAKE REPOSITORY - Giả lập kho dữ liệu thể loại trong RAM
/// Bước 6 trong kiến trúc Compass App:
/// Phục vụ Unit Test & Widget Test nhanh chóng, độc lập với mạng.
class FakeGenreRepository implements GenreRepository {
  final List<Genre> _items;
  final bool shouldThrowError;

  FakeGenreRepository([
    List<Genre>? initialItems,
    this.shouldThrowError = false,
  ]) : _items = initialItems != null
           ? List.of(initialItems)
           : [
               const Genre(
                 id: 'genre-action',
                 name: 'Hành Động',
                 description: 'Truyện hành động hấp dẫn kịch tính',
                 seriesCount: 12,
               ),
               const Genre(
                 id: 'genre-adventure',
                 name: 'Phiêu Lưu',
                 description: 'Khám phá những vùng đất mới lạ',
                 seriesCount: 8,
               ),
               const Genre(
                 id: 'genre-fantasy',
                 name: 'Kỳ Ảo',
                 description: 'Thế giới phép thuật và huyền bí',
                 seriesCount: 15,
               ),
               const Genre(
                 id: 'genre-romance',
                 name: 'Ngôn Tình',
                 description: 'Những câu chuyện tình yêu ngọt ngào sâu lắng',
                 seriesCount: 10,
               ),
               const Genre(
                 id: 'genre-mystery',
                 name: 'Trinh Thám',
                 description: 'Phá án ly kỳ hồi hộp từng trang sách',
                 seriesCount: 6,
               ),
               const Genre(
                 id: 'genre-scifi',
                 name: 'Khoa Huyễn',
                 description: 'Công nghệ tương lai và vũ trụ vô tận',
                 seriesCount: 5,
               ),
             ];

  @override
  Future<List<Genre>> getGenres() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw const AppException(
        message: 'Lỗi kết nối máy chủ khi tải danh mục thể loại.',
      );
    }
    return List.unmodifiable(_items);
  }
}
