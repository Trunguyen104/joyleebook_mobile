import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/dtos/ai_recommendation_dto.dart';
import 'package:joyleebook_mobile/domain/models/ai_recommendation.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';

void main() {
  group('AiRecommendationDto Tests', () {
    test('Parse SemanticSearchResponseDto từ JSON chuẩn backend', () {
      final json = {
        'query': 'kiem hiep',
        'totalFound': 2,
        'items': [
          {
            'series': {
              'id': 'e0000000-0000-4000-8000-000000000002',
              'authorId': 'd0000000-0000-4000-8000-000000000007',
              'title': 'Kiếm Khách Phương Nam',
              'description': 'Thiếu niên kiếm hiệp...',
              'coverImageUrl': 'https://example.com/cover1.jpg',
              'status': 1,
              'isPublish': true,
              'genres': [
                {'id': '1', 'name': 'Hành Động'},
                {'id': '2', 'name': 'Kiếm Hiệp'},
              ],
              'metrics': {'averageRating': 4.5, 'ratingCount': 10},
            },
            'relevanceScore': 0.887,
          },
        ],
      };

      final dto = SemanticSearchResponseDto.fromJson(json);

      expect(dto.query, 'kiem hiep');
      expect(dto.totalFound, 2);
      expect(dto.items.length, 1);

      final item = dto.items.first;
      expect(item.relevanceScore, 0.887);
      expect(item.series.title, 'Kiếm Khách Phương Nam');
      expect(item.series.genreNames, ['Hành Động', 'Kiếm Hiệp']);
      expect(item.series.averageRating, 4.5);
    });

    test('Parse SimilarSeriesListResponseDto từ JSON chuẩn backend', () {
      final json = {
        'sourceSeriesId': 'source-guid-123',
        'isFallbackByGenre': false,
        'items': [
          {
            'series': {
              'id': 'target-guid-456',
              'authorId': 'author-789',
              'title': 'Truyện Tương Đồng',
              'description': 'Mô tả truyện...',
              'coverImageUrl': 'https://example.com/cover2.jpg',
              'status': 0,
              'isPublish': true,
              'genres': [
                {'name': 'Kỳ Ảo'},
              ],
            },
            'similarityScore': 0.925,
          },
        ],
      };

      final dto = SimilarSeriesListResponseDto.fromJson(json);

      expect(dto.sourceSeriesId, 'source-guid-123');
      expect(dto.isFallbackByGenre, false);
      expect(dto.items.length, 1);

      final item = dto.items.first;
      expect(item.similarityScore, 0.925);
      expect(item.series.title, 'Truyện Tương Đồng');
      expect(item.series.status, 0);
    });

    test('AiRecommendation Domain Model tính matchPercentage chính xác', () {
      const recHigh = AiRecommendation(
        series: Series(
          id: '1',
          title: 'Test',
          authorName: 'Author',
          description: '',
          coverImageUrl: '',
          status: SeriesStatus.ongoing,
        ),
        score: 0.856,
      );
      expect(recHigh.matchPercentage, 86);

      const recMax = AiRecommendation(
        series: Series(
          id: '2',
          title: 'Test',
          authorName: 'Author',
          description: '',
          coverImageUrl: '',
          status: SeriesStatus.ongoing,
        ),
        score: 1.2,
      );
      expect(recMax.matchPercentage, 100);

      const recMin = AiRecommendation(
        series: Series(
          id: '3',
          title: 'Test',
          authorName: 'Author',
          description: '',
          coverImageUrl: '',
          status: SeriesStatus.ongoing,
        ),
        score: -0.5,
      );
      expect(recMin.matchPercentage, 0);
    });
  });
}
