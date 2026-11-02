import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';

void main() {
  test('Dùng seriesId thay vì id bản ghi bookmark khi tải tủ sách', () async {
    final requestPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requestPaths.add(options.path);
          if (options.method == 'GET') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: [
                  {
                    'id': 'bookmark-record-id',
                    'seriesId': 'series-guid',
                    'title': 'Truyện thử',
                    'authorName': 'Tác giả',
                  },
                ],
              ),
            );
            return;
          }
          handler.resolve(Response<dynamic>(requestOptions: options));
        },
      ),
    );
    final repository = SeriesRepository(dio);

    final bookmarks = await repository.getBookmarkedSeries();
    expect(bookmarks.single.id, 'series-guid');

    await repository.toggleBookmark(bookmarks.single.id, false);
    expect(requestPaths.last, '/api/library/bookmarks/series-guid');
  });
}
