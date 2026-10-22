import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/chapter.dart';
import 'package:joyleebook_mobile/domain/models/chapter_detail.dart';

/// FAKE REPOSITORY - Giả lập dữ liệu chương trong bộ nhớ
class FakeChapterRepository implements ChapterRepository {
  final List<Chapter> chapters;
  final bool shouldThrowError;

  FakeChapterRepository([
    this.chapters = const [],
    this.shouldThrowError = false,
  ]);

  @override
  Future<List<Chapter>> getChaptersBySeries(String seriesId) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Lỗi tải danh sách chương giả lập.');
    }
    return chapters.where((c) => c.seriesId == seriesId).toList();
  }

  @override
  Future<ChapterDetail> getChapterDetail(String chapterId) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (shouldThrowError) {
      throw AppException(message: 'Lỗi tải nội dung chương giả lập.');
    }
    return ChapterDetail(
      id: chapterId,
      seriesId: '1',
      title: 'Chương thử nghiệm',
      content: 'Nội dung đọc thử nghiệm...',
      sortOrder: 1,
      totalChapters: 10,
      status: 1,
    );
  }
}
