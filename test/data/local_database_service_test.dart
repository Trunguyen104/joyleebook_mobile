import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:joyleebook_mobile/data/services/local_database_service.dart';
import 'package:joyleebook_mobile/domain/models/chapter_detail.dart';

void main() {
  late LocalDatabaseService database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    database = LocalDatabaseService();
  });

  test('lưu và đọc lại nội dung chapter theo userId', () async {
    const userId = 'offline-test-user-1';
    const chapter = ChapterDetail(
      id: 'chapter-offline-1',
      seriesId: 'series-offline-1',
      title: 'Chương ngoại tuyến',
      content: 'Nội dung được lưu trong SQLite.',
      sortOrder: 1,
      totalChapters: 3,
      status: 1,
      publishedAt: null,
    );

    await database.saveChapter(
      userId: userId,
      seriesId: chapter.seriesId,
      seriesTitle: 'Truyện offline',
      chapter: chapter,
    );
    final saved = await database.getChapter(
      userId: userId,
      chapterId: chapter.id,
    );

    expect(saved, isNotNull);
    expect(saved!.content, chapter.content);
    expect(
      await database.getDownloadedChapterIds(
        userId: userId,
        seriesId: chapter.seriesId,
      ),
      contains(chapter.id),
    );

    await database.deleteUser(userId);
  });

  test('không cho user khác đọc nội dung offline', () async {
    const owner = 'offline-test-owner';
    const otherUser = 'offline-test-other';
    const chapter = ChapterDetail(
      id: 'chapter-private-1',
      seriesId: 'series-private-1',
      title: 'Chương riêng tư',
      content: 'Nội dung riêng theo tài khoản.',
      sortOrder: 2,
      totalChapters: 2,
      status: 1,
      publishedAt: null,
    );

    await database.saveChapter(
      userId: owner,
      seriesId: chapter.seriesId,
      seriesTitle: 'Truyện riêng tư',
      chapter: chapter,
    );

    expect(
      await database.getChapter(userId: otherUser, chapterId: chapter.id),
      isNull,
    );

    await database.deleteUser(owner);
  });

  test(
    'nhóm chapter theo series và xóa series khi chapter cuối bị xóa',
    () async {
      const userId = 'offline-group-user';
      const first = ChapterDetail(
        id: 'group-chapter-1',
        seriesId: 'group-series',
        title: 'Chương 1',
        content: 'Một',
        sortOrder: 1,
        totalChapters: 2,
        status: 1,
        publishedAt: null,
      );
      const second = ChapterDetail(
        id: 'group-chapter-2',
        seriesId: 'group-series',
        title: 'Chương 2',
        content: 'Hai',
        sortOrder: 2,
        totalChapters: 2,
        status: 1,
        publishedAt: null,
      );

      await database.saveChapter(
        userId: userId,
        seriesId: first.seriesId,
        seriesTitle: 'Truyện nhóm',
        coverImageUrl: 'cover.jpg',
        chapter: first,
      );
      await database.saveChapter(
        userId: userId,
        seriesId: second.seriesId,
        seriesTitle: 'Truyện nhóm',
        coverImageUrl: 'cover.jpg',
        chapter: second,
      );

      var series = await database.getOfflineSeries(userId);
      expect(series, hasLength(1));
      expect(series.single.chapters, hasLength(2));
      expect(series.single.coverImageUrl, 'cover.jpg');

      await database.deleteChapter(userId: userId, chapterId: first.id);
      series = await database.getOfflineSeries(userId);
      expect(series.single.chapters, hasLength(1));

      await database.deleteChapter(userId: userId, chapterId: second.id);
      expect(await database.getOfflineSeries(userId), isEmpty);
    },
  );
}
