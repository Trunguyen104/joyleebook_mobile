import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/chapter_detail.dart';
import '../../domain/models/offline_chapter.dart';
import '../../domain/models/offline_series.dart';
import '../services/local_database_service.dart';

class OfflineChapterRepository {
  OfflineChapterRepository(this._database);

  final LocalDatabaseService _database;

  Future<void> save(
    String userId,
    String seriesTitle,
    ChapterDetail chapter, {
    String? seriesId,
    String authorName = '',
    String coverImageUrl = '',
    int status = 1,
    int totalChapters = 0,
  }) => _database.saveChapter(
    userId: userId,
    seriesId: seriesId ?? chapter.seriesId,
    seriesTitle: seriesTitle,
    authorName: authorName,
    coverImageUrl: coverImageUrl,
    status: status,
    totalChapters: totalChapters,
    chapter: chapter,
  );

  Future<OfflineChapter?> get(String userId, String chapterId) =>
      _database.getChapter(userId: userId, chapterId: chapterId);

  Future<Set<String>> getIds(String userId, String seriesId) =>
      _database.getDownloadedChapterIds(userId: userId, seriesId: seriesId);

  Future<List<OfflineChapter>> getAll(String userId) =>
      _database.getAllChapters(userId);

  Future<List<OfflineSeries>> getSeries(String userId) =>
      _database.getOfflineSeries(userId);

  Future<void> delete(String userId, String chapterId) =>
      _database.deleteChapter(userId: userId, chapterId: chapterId);

  Future<void> deleteSeries(String userId, String seriesId) =>
      _database.deleteSeries(userId: userId, seriesId: seriesId);

  Future<void> deleteUser(String userId) => _database.deleteUser(userId);
}

final offlineChapterRepositoryProvider = Provider<OfflineChapterRepository>(
  (ref) => OfflineChapterRepository(ref.watch(localDatabaseServiceProvider)),
);
