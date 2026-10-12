import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_list_screen.dart';
import '../../testing/fakes/fake_series_repository.dart';

void main() {
  testWidgets('Hiển thị JoyleeEmptyState khi danh sách truyện rỗng', (tester) async {
    // 1. Khởi tạo Fake Repository rỗng
    final fakeRepo = FakeSeriesRepository([]);

    // 2. Bọc Widget trong ProviderScope và ghi đè (override) seriesRepositoryProvider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SeriesListScreen(),
        ),
      ),
    );

    // 3. Đợi cho tất cả hiệu ứng và bất đồng bộ hoàn thành
    await tester.pumpAndSettle();

    // 4. Kiểm tra xem Empty State có xuất hiện trên màn hình hay không
    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Không tìm thấy truyện nào'), findsOneWidget);
  });

  testWidgets('Hiển thị danh sách truyện khi có dữ liệu từ Repository', (tester) async {
    // 1. Khởi tạo Fake Repository có 1 truyện mẫu
    final mockData = [
      const Series(
        id: '1',
        title: 'Bí Mật Cổ Trấn Giữa Sương Mù',
        authorName: 'Nguyên Phong',
        description: 'Chuyến hành trình khám phá bí ẩn...',
        coverImageUrl: '',
        status: SeriesStatus.ongoing,
        genres: ['Phiêu Lưu'],
      ),
    ];
    final fakeRepo = FakeSeriesRepository(mockData);

    // 2. Chạy widget với dữ liệu giả lập
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SeriesListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 3. Xác nhận tên truyện và tác giả hiển thị chính xác
    expect(find.text('Bí Mật Cổ Trấn Giữa Sương Mù'), findsOneWidget);
    expect(find.text('Nguyên Phong'), findsOneWidget);
  });
}
