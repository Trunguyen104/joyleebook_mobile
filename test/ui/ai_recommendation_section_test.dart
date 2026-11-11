import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/series/widgets/ai_custom_prompt_bottom_sheet.dart';
import 'package:joyleebook_mobile/ui/series/widgets/ai_recommendation_section.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_list_screen.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

void main() {
  const mockSeries1 = Series(
    id: '1',
    title: 'Kiếm Khách Phương Nam',
    authorName: 'Độc Cô Cầu Bại',
    description: 'Chàng thiếu niên kiếm hiệp...',
    coverImageUrl: '',
    status: SeriesStatus.ongoing,
    genres: ['Kiếm Hiệp'],
    averageRating: 4.8,
  );

  const mockSeries2 = Series(
    id: '2',
    title: 'Hồi Ức Người Lữ Khách',
    authorName: 'Nguyên Phong',
    description: 'Phiêu lưu dị giới...',
    coverImageUrl: '',
    status: SeriesStatus.completed,
    genres: ['Phiêu Lưu'],
    averageRating: 4.6,
  );

  testWidgets(
    'Hiển thị Section AI Recommendation trên Trang chủ SeriesListScreen',
    (tester) async {
      final fakeRepo = FakeSeriesRepository([mockSeries1, mockSeries2]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SeriesListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Kiểm tra sự xuất hiện của AiRecommendationSection
      expect(find.byType(AiRecommendationSection), findsOneWidget);

      // 2. Kiểm tra biểu tượng AI và tiêu đề
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
      expect(find.text('AI Gợi ý cho bạn'), findsOneWidget);

      // 3. Kiểm tra các chip gu đọc nhanh
      expect(find.text('Gợi ý cho bạn'), findsOneWidget);
      expect(find.text('Tu tiên'), findsOneWidget);
      expect(find.text('✨ Nhập gu riêng...'), findsOneWidget);

      // 4. Kiểm tra thẻ truyện và huy hiệu % phù hợp
      expect(find.text('Kiếm Khách Phương Nam'), findsWidgets);
    },
  );

  testWidgets(
    'Bấm chip ✨ Nhập gu riêng... hiển thị AiCustomPromptBottomSheet',
    (tester) async {
      final fakeRepo = FakeSeriesRepository([mockSeries1, mockSeries2]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(fakeRepo),
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SeriesListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Bấm vào chip nhập gu riêng (cuộn ngang nếu cần)
      final customPromptChip = find.text('✨ Nhập gu riêng...');
      expect(customPromptChip, findsOneWidget);
      await tester.ensureVisible(customPromptChip);
      await tester.pumpAndSettle();
      await tester.tap(customPromptChip);
      await tester.pumpAndSettle();

      // Kiểm tra BottomSheet xuất hiện
      expect(find.byType(AiCustomPromptBottomSheet), findsOneWidget);
      expect(find.text('Tìm truyện cùng Trợ lý AI'), findsOneWidget);
      expect(find.text('AI Gợi ý ngay'), findsOneWidget);
    },
  );
}
