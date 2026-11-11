import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/reading_history.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/bookmark_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';

import '../../testing/fakes/fake_series_repository.dart';

const _series = Series(
  id: 'series-1',
  title: 'Hành Trình Về Phương Đông',
  authorName: 'Nguyên Phong',
  description: 'Tác phẩm kinh điển.',
  coverImageUrl: '',
  status: SeriesStatus.completed,
  isBookmarked: true,
);

final _history = [
  ReadingHistory(
    seriesId: _series.id,
    series: _series,
    chapterTitle: 'Hội thảo khoa học',
    chapterNumber: 2,
    progress: 0.4,
    lastReadAt: DateTime(2026, 11, 1),
  ),
];

Widget _buildApp(FakeSeriesRepository repository) => ProviderScope(
  overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(theme: AppTheme.light, home: const BookmarkScreen()),
);

void main() {
  testWidgets('Tủ sách có đúng ba tab và mặc định là Đang đọc', (tester) async {
    await tester.pumpWidget(_buildApp(FakeSeriesRepository([])));
    await tester.pumpAndSettle();

    expect(find.text('Đang đọc'), findsOneWidget);
    expect(find.text('Đã lưu'), findsOneWidget);
    expect(find.text('Tải xuống'), findsOneWidget);
    expect(find.text('Chưa có lịch sử đọc'), findsOneWidget);
  });

  testWidgets('Tab Đã lưu hiển thị các series đã bookmark', (tester) async {
    await tester.pumpWidget(
      _buildApp(FakeSeriesRepository.withHistory([_series])),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();

    expect(find.text(_series.title), findsOneWidget);
    expect(find.byTooltip('Bỏ lưu'), findsOneWidget);
  });

  testWidgets('Tab Đang đọc hiển thị chapter và tiến độ gần nhất', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        FakeSeriesRepository.withHistory([_series], readingHistory: _history),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(_series.title), findsOneWidget);
    expect(find.textContaining('Hội thảo khoa học'), findsOneWidget);
    expect(find.text('Tiến độ 40%'), findsOneWidget);
  });

  testWidgets('Bỏ lưu trong tab Đã lưu cập nhật danh sách ngay', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(FakeSeriesRepository([_series])));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bỏ lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Tủ sách đang trống'), findsOneWidget);
    expect(
      find.text('Đã bỏ lưu "${_series.title}" khỏi tủ sách.'),
      findsOneWidget,
    );
  });

  testWidgets('Chuyển qua tab Tải xuống không gây overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildApp(
        FakeSeriesRepository.withHistory([_series], readingHistory: _history),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tải xuống'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có truyện tải xuống'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
