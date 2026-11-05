import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/dtos/upsert_reading_progress_dto.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';

void main() {
  test('Tải và ánh xạ lịch sử đọc với trường null an toàn', () async {
    final requestPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestPaths.add(options.path);
          final responseData = options.path == '/api/library/history'
              ? {
                  'items': [
                    {
                      'SeriesId': 'series-1',
                      'ChapterId': 'chapter-8',
                      'ChapterSortOrder': 8,
                      'ScrollPercentage': 45,
                      'LastReadAtUtc': '2026-11-04T10:00:00Z',
                    },
                    {
                      'SeriesId': 'series-1',
                      'ChapterSortOrder': 4,
                      'ScrollPercentage': 10,
                      'LastReadAtUtc': '2026-11-03T10:00:00Z',
                    },
                  ],
                }
              : {'id': 'series-1', 'title': null, 'coverImageUrl': null};
          handler.resolve(
            Response<dynamic>(requestOptions: options, data: responseData),
          );
        },
      ),
    );

    final history = await SeriesRepository(dio).getReadingHistory();

    expect(requestPaths.first, '/api/library/history');
    expect(requestPaths, contains('/api/series/series-1'));
    expect(history, hasLength(1));
    expect(history.single.series.title, 'Chưa có tiêu đề');
    expect(history.single.series.coverImageUrl, isEmpty);
    expect(history.single.chapterTitle, isNull);
    expect(history.single.chapterNumber, 8);
    expect(history.single.progress, 0.45);
  });

  test('Tải tiến độ theo seriesId qua Library API', () async {
    final requestPaths = <String>[];
    final requestQueries = <Map<String, dynamic>>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestPaths.add(options.path);
          requestQueries.add(options.queryParameters);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: {'scrollPercentage': 0.73},
            ),
          );
        },
      ),
    );

    final progress = await SeriesRepository(dio).getReadingProgress('series-2');

    expect(requestPaths, ['/api/library/progress']);
    expect(requestQueries.single, {'seriesId': 'series-2'});
    expect(progress, 0.73);
  });

  test('Ghi tiến độ theo hợp đồng PUT của Library API', () async {
    final requestPaths = <String>[];
    final requestBodies = <dynamic>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestPaths.add(options.path);
          requestBodies.add(options.data);
          handler.resolve(Response<dynamic>(requestOptions: options));
        },
      ),
    );

    await SeriesRepository(dio).updateReadingProgress(
      UpsertReadingProgressDto(
        seriesId: 'series-3',
        chapterId: 'chapter-7',
        chapterSortOrder: 7,
        scrollPercentage: 42.5,
        isCompleted: false,
        readAtUtc: DateTime.utc(2026, 11, 5),
      ),
    );

    expect(requestPaths, ['/api/library/progress']);
    expect(requestBodies.single, {
      'seriesId': 'series-3',
      'chapterId': 'chapter-7',
      'chapterSortOrder': 7,
      'scrollPercentage': 42.5,
      'isCompleted': false,
      'readAtUtc': '2026-11-05T00:00:00.000Z',
    });
  });
}
