import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/genre_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/genre.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/search/widgets/search_genre_bottom_sheet.dart';
import 'package:joyleebook_mobile/ui/search/widgets/search_screen.dart';

import '../../testing/fakes/fake_genre_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

void main() {
  final sampleGenres = [
    const Genre(
      id: 'g-action',
      name: 'Hành Động',
      description: 'Kịch tính và lôi cuốn',
      seriesCount: 5,
    ),
    const Genre(
      id: 'g-fantasy',
      name: 'Kỳ Ảo',
      description: 'Thế giới huyền bí',
      seriesCount: 8,
    ),
  ];

  final sampleSeries = [
    const Series(
      id: 's1',
      title: 'Đấu Phá Thương Khung',
      authorName: 'Thiên Tằm Thổ Đậu',
      description: 'Tu luyện dị hỏa',
      coverImageUrl: '',
      status: SeriesStatus.ongoing,
      genres: ['Kỳ Ảo'],
    ),
    const Series(
      id: 's2',
      title: 'Sát Thủ Về Hưu',
      authorName: 'John Wick',
      description: 'Hành động bắn súng',
      coverImageUrl: '',
      status: SeriesStatus.completed,
      genres: ['Hành Động'],
    ),
  ];

  Widget createWidget({
    List<Series>? series,
    List<Genre>? genres,
    bool seriesError = false,
    bool genreError = false,
    String? initialGenre,
  }) {
    return ProviderScope(
      overrides: [
        seriesRepositoryProvider.overrideWithValue(
          FakeSeriesRepository(series ?? sampleSeries, seriesError),
        ),
        genreRepositoryProvider.overrideWithValue(
          FakeGenreRepository(genres ?? sampleGenres, genreError),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: SearchScreen(initialGenre: initialGenre),
      ),
    );
  }

  group('SearchScreen - Widget Tests', () {
    testWidgets('Hiển thị đầy đủ ô tìm kiếm, thanh danh mục thể loại, số lượng truyện và nút Lọc', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Kiểm tra ô tìm kiếm
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tìm truyện hoặc người'), findsOneWidget);

      // Kiểm tra nút Lọc
      expect(find.text('Lọc'), findsOneWidget);

      // Kiểm tra các tab thể loại
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Hành Động'), findsOneWidget);
      expect(find.text('Kỳ Ảo'), findsOneWidget);

      // Kiểm tra hiển thị cả 2 tác phẩm ban đầu dạng xếp hạng
      expect(find.text('Đấu Phá Thương Khung'), findsOneWidget);
      expect(find.text('Sát Thủ Về Hưu'), findsOneWidget);
    });

    testWidgets('Bấm chọn thể loại -> Lọc danh sách tác phẩm tương ứng', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Nhấn vào tab "Kỳ Ảo" trên thanh thể loại
      await tester.tap(find.text('Kỳ Ảo'));
      await tester.pumpAndSettle();

      // Chỉ hiển thị Đấu Phá Thương Khung
      expect(find.text('Đấu Phá Thương Khung'), findsOneWidget);
      expect(find.text('Sát Thủ Về Hưu'), findsNothing);
    });

    testWidgets('Nhập từ khóa tìm kiếm với Debounce 400ms', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Nhập từ khóa
      await tester.enterText(find.byType(TextField), 'John Wick');
      await tester.pump(const Duration(milliseconds: 200));

      // Chưa đủ 400ms -> vẫn hiển thị danh sách cũ
      expect(find.text('Đấu Phá Thương Khung'), findsOneWidget);

      // Đợi hết 400ms debounce
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Đã lọc ra Sát Thủ Về Hưu
      expect(find.text('Sát Thủ Về Hưu'), findsOneWidget);
      expect(find.text('Đấu Phá Thương Khung'), findsNothing);
    });

    testWidgets('Khi không tìm thấy kết quả -> Hiển thị JoyleeEmptyState', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tìm từ khóa không có thật
      await tester.enterText(find.byType(TextField), 'zzzzzzzzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Empty State xuất hiện
      expect(find.byType(JoyleeEmptyState), findsOneWidget);
      expect(find.text('Không tìm thấy tác phẩm nào'), findsOneWidget);

      // Bấm "Xóa bộ lọc" -> Khôi phục danh sách
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();

      expect(find.text('Đấu Phá Thương Khung'), findsOneWidget);
      expect(find.text('Sát Thủ Về Hưu'), findsOneWidget);
    });

    testWidgets('Mở Modal Bottom Sheet xem tất cả thể loại và bộ lọc trạng thái', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Bấm nút "Lọc"
      await tester.tap(find.text('Lọc'));
      await tester.pumpAndSettle();

      // Xác nhận Bottom Sheet hiển thị
      expect(find.byType(SearchGenreBottomSheet), findsOneWidget);
      expect(find.text('Tất cả Thể loại & Bộ lọc'), findsOneWidget);
      expect(find.text('Trạng thái phát hành'), findsOneWidget);
      expect(find.text('Danh mục Thể loại'), findsOneWidget);
    });

    testWidgets('Xử lý lỗi mạng khi tìm kiếm -> Hiển thị JoyleeErrorView và nút Thử lại', (tester) async {
      await tester.pumpWidget(createWidget(seriesError: true));
      await tester.pumpAndSettle();

      expect(find.byType(JoyleeErrorView), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('Bấm nút mở rộng trên thanh thể loại -> Hiển thị Dropdown panel Wattpad và bấm chọn chip lọc', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Ban đầu chưa mở dropdown, nút chevron up chưa có
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);

      // Bấm nút mở rộng (chevron right) trên thanh thể loại
      await tester.tap(find.byIcon(Icons.keyboard_arrow_right_rounded));
      await tester.pumpAndSettle();

      // Dropdown panel mở ra với nút ^ thu gọn
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsAtLeastNWidgets(1));

      // Bấm vào chip 'Kỳ Ảo' trong dropdown panel
      final kyAoChips = find.text('Kỳ Ảo');
      expect(kyAoChips, findsAtLeastNWidgets(1));
      await tester.tap(kyAoChips.last);
      await tester.pumpAndSettle();

      // Sau khi chọn chip, dropdown panel tự động đóng lại
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);

      // Danh sách truyện được lọc theo 'Kỳ Ảo'
      expect(find.text('Đấu Phá Thương Khung'), findsOneWidget);
      expect(find.text('Sát Thủ Về Hưu'), findsNothing);
    });
  });
}
