import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/dtos/comment_dto.dart';
import 'package:joyleebook_mobile/data/repositories/comment_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/comment.dart';

void main() {
  group('CommentDto & Model mapping', () {
    test('Map chính xác từ JSON sang CommentDto và Domain Model', () {
      final json = {
        'id': 'comment-123',
        'seriesId': 'series-456',
        'chapterId': 'chapter-789',
        'userId': 'user-001',
        'username': 'reader_tester',
        'content': 'Truyện rất cuốn hút!',
        'createdAt': '2026-11-09T08:00:00Z',
        'updatedAt': '2026-11-09T08:30:00Z',
        'isEdited': true,
      };

      final dto = CommentDto.fromJson(json);
      expect(dto.id, 'comment-123');
      expect(dto.seriesId, 'series-456');
      expect(dto.chapterId, 'chapter-789');
      expect(dto.username, 'reader_tester');
      expect(dto.content, 'Truyện rất cuốn hút!');
      expect(dto.isEdited, isTrue);

      final model = Comment.fromDto(dto);
      expect(model.id, dto.id);
      expect(model.seriesId, dto.seriesId);
      expect(model.chapterId, dto.chapterId);
      expect(model.username, dto.username);
      expect(model.content, dto.content);
      expect(model.isEdited, isTrue);
    });

    test('Map PagedCommentsDto', () {
      final json = {
        'items': [
          {
            'id': 'comment-1',
            'seriesId': 's-1',
            'userId': 'u-1',
            'username': 'reader1',
            'content': 'Hay quá',
            'createdAt': '2026-11-09T08:00:00Z',
            'updatedAt': '2026-11-09T08:00:00Z',
            'isEdited': false,
          },
        ],
        'page': 1,
        'pageSize': 10,
        'totalCount': 1,
        'totalPages': 1,
      };

      final pagedDto = PagedCommentsDto.fromJson(json);
      expect(pagedDto.items.length, 1);
      expect(pagedDto.totalCount, 1);

      final pagedModel = PagedComments.fromDto(pagedDto);
      expect(pagedModel.items.length, 1);
      expect(pagedModel.items.first.content, 'Hay quá');
    });
  });

  group('CommentRepository', () {
    test('getComments gửi đúng query params', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/comments');
            expect(options.queryParameters['seriesId'], 'series-1');
            expect(options.queryParameters['chapterId'], 'chapter-1');
            expect(options.queryParameters['page'], 1);
            expect(options.queryParameters['pageSize'], 10);

            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: {
                  'items': [],
                  'page': 1,
                  'pageSize': 10,
                  'totalCount': 0,
                  'totalPages': 0,
                },
              ),
            );
          },
        ),
      );

      final repo = CommentRepository(dio);
      final res = await repo.getComments(
        seriesId: 'series-1',
        chapterId: 'chapter-1',
        page: 1,
        pageSize: 10,
      );
      expect(res.items, isEmpty);
      expect(res.totalCount, 0);
    });

    test('createComment gửi đúng POST body', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/comments');
            expect(options.method, 'POST');
            final data = options.data as Map<String, dynamic>;
            expect(data['seriesId'], 'series-1');
            expect(data['chapterId'], 'chapter-1');
            expect(data['content'], 'Bình luận mới');

            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                data: {
                  'id': 'new-id',
                  'seriesId': 'series-1',
                  'chapterId': 'chapter-1',
                  'userId': 'user-1',
                  'username': 'reader1',
                  'content': 'Bình luận mới',
                  'createdAt': '2026-11-09T08:00:00Z',
                  'updatedAt': '2026-11-09T08:00:00Z',
                  'isEdited': false,
                },
              ),
            );
          },
        ),
      );

      final repo = CommentRepository(dio);
      final comment = await repo.createComment(
        seriesId: 'series-1',
        chapterId: 'chapter-1',
        content: 'Bình luận mới',
      );
      expect(comment.id, 'new-id');
      expect(comment.content, 'Bình luận mới');
    });

    test('deleteComment gọi đúng endpoint DELETE', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/api/comments/comment-to-delete');
            expect(options.method, 'DELETE');
            handler.resolve(
              Response<void>(requestOptions: options, statusCode: 204),
            );
          },
        ),
      );

      final repo = CommentRepository(dio);
      await expectLater(repo.deleteComment('comment-to-delete'), completes);
    });

    test('Bắt DioException và ném AppException', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

      final repo = CommentRepository(dio);
      expect(
        () => repo.getComments(seriesId: 'series-1'),
        throwsA(isA<AppException>()),
      );
    });
  });
}
