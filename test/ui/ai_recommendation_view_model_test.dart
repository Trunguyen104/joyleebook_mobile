import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/reading_history.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/auth/view_models/auth_session_view_model.dart';
import 'package:joyleebook_mobile/ui/series/view_models/ai_recommendation_view_model.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

void main() {
  const mockSeries1 = Series(
    id: 'series-1',
    title: 'Đại Đạo Triều Thiên',
    authorName: 'Miêu Nị',
    description: 'Tu chân truyền kỳ...',
    coverImageUrl: '',
    status: SeriesStatus.completed,
    genres: ['Tiên Hiệp'],
  );

  const mockSeries2 = Series(
    id: 'series-2',
    title: 'Kiếm Lai',
    authorName: 'Phong Hỏa',
    description: 'Kiếm đạo đỉnh cao...',
    coverImageUrl: '',
    status: SeriesStatus.ongoing,
    genres: ['Kiếm Hiệp'],
  );

  group('AiRecommendationViewModel Tests', () {
    test(
      'Khách chưa đăng nhập: Nạp gợi ý qua Semantic Search mặc định',
      () async {
        final fakeRepo = FakeSeriesRepository([mockSeries1, mockSeries2]);
        final container = ProviderContainer(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
        );
        addTearDown(container.dispose);

        // Đợi session tải xong
        await container.read(authSessionProvider.future);

        final state = await container.read(
          aiRecommendationViewModelProvider.future,
        );

        expect(state.items.isNotEmpty, true);
        expect(state.sourceSeriesTitle, isNull);
        expect(state.activePrompt, isNull);
      },
    );

    test('Độc giả có lịch sử đọc: Ưu tiên gợi ý theo truyện đọc gần nhất (Vector Similarity)', () async {
      final history = [
        const ReadingHistory(
          seriesId: 'series-1',
          series: mockSeries1,
          chapterId: 'chap-1',
          chapterTitle: 'Chương 1',
          chapterNumber: 1,
          progress: 0.5,
        ),
      ];

      final fakeRepo = FakeSeriesRepository.withHistory([
        mockSeries1,
        mockSeries2,
      ], readingHistory: history);

      final container = ProviderContainer(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(savedSession: fakeSession),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Đợi session tải xong
      await container.read(authSessionProvider.future);

      final state = await container.read(
        aiRecommendationViewModelProvider.future,
      );

      expect(state.sourceSeriesTitle, 'Đại Đạo Triều Thiên');
      expect(state.items.isNotEmpty, true);
    });

    test(
      'filterByPrompt: Cập nhật danh sách truyện theo gu đọc AI riêng',
      () async {
        final fakeRepo = FakeSeriesRepository([mockSeries1, mockSeries2]);
        final container = ProviderContainer(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
        );
        addTearDown(container.dispose);

        // Đợi session tải xong
        await container.read(authSessionProvider.future);

        // Khởi tạo
        await container.read(aiRecommendationViewModelProvider.future);

        // Lọc theo prompt
        await container
            .read(aiRecommendationViewModelProvider.notifier)
            .filterByPrompt('truyện hài hước', chipLabel: 'Hài hước');

        final state = container.read(aiRecommendationViewModelProvider).value!;
        expect(state.activePrompt, 'truyện hài hước');
        expect(state.activeChip, 'Hài hước');
        expect(state.items.isNotEmpty, true);
      },
    );
  });
}
