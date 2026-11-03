import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/genre_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/genre.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/series/widgets/genre_bottom_sheet.dart';
import 'package:joyleebook_mobile/ui/series/widgets/genre_filter_bar.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_list_screen.dart';

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
    bool genreError = false,
  }) {
    return ProviderScope(
      overrides: [
        seriesRepositoryProvider.overrideWithValue(
          FakeSeriesRepository(series ?? sampleSeries),
        ),
        genreRepositoryProvider.overrideWithValue(
          FakeGenreRepository(genres ?? sampleGenres, genreError),
        ),
      ],
      child: const MaterialApp(
        home: SeriesListScreen(),
      ),
    );
  }

  group('Research & View Genres - Widget Tests', () {
    testWidgets('Hiển thị đầy đủ ô tìm kiếm, chip Tất cả, Bộ lọc và danh sách thể loại', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Kiểm tra ô tìm kiếm
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tìm kiếm tựa truyện, tác giả...'), findsOneWidget);

      // Kiểm tra thanh thể loại
      expect(find.byType(GenreFilterBar), findsOneWidget);
      expect(find.text('Bộ lọc'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Tất cả'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Hành Động'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Kỳ Ảo'), findsOneWidget);

      // Kiểm tra hiển thị cả 2 tác phẩm ban đầu
      expect(find.text('Đấu Phá Thương Khung'), findsOneWidget);
      expect(find.text('Sát Thủ Về Hưu'), findsOneWidget);
    });

    testWidgets('Bấm chọn thể loại -> Lọc danh sách tác phẩm tương ứng', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Nhấn vào ChoiceChip "Kỳ Ảo" trên thanh thể loại
      await tester.tap(find.widgetWithText(ChoiceChip, 'Kỳ Ảo'));
      await tester.pumpAndSettle();

      // Chỉ hiển thị tác phẩm Kỳ Ảo
      expect(find.text('Đấu Phá Thương Khung'), findsOneWidget);
      expect(find.text('Sát Thủ Về Hưu'), findsNothing);

      // Banner bộ lọc hiển thị
      expect(find.textContaining('Tìm thấy 1 tác phẩm phù hợp'), findsOneWidget);
      expect(find.text('Xóa bộ lọc'), findsOneWidget);
    });

    testWidgets('Tìm kiếm từ khóa với Debounce 400ms', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Nhập từ khóa tìm kiếm
      await tester.enterText(find.byType(TextField), 'John Wick');
      // Chưa đủ 400ms -> chưa lọc ngay
      await tester.pump(const Duration(milliseconds: 200));
      // Hết 400ms debounce
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Chỉ hiển thị tác phẩm của John Wick
      expect(find.text('Sát Thủ Về Hưu'), findsOneWidget);
      expect(find.text('Đấu Phá Thương Khung'), findsNothing);
    });

    testWidgets('Bộ lọc không có kết quả -> Hiển thị JoyleeEmptyState và nút Xóa bộ lọc', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tìm kiếm từ khóa không tồn tại
      await tester.enterText(find.byType(TextField), 'KhongTonTai123');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Hiển thị Empty State
      expect(find.byType(JoyleeEmptyState), findsOneWidget);
      expect(find.text('Không tìm thấy truyện nào'), findsOneWidget);
      expect(find.text('Xóa bộ lọc'), findsOneWidget);

      // Bấm nút "Xóa bộ lọc" -> Khôi phục toàn bộ danh sách
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();

      expect(find.text('Đấu Phá Thương Khung'), findsOneWidget);
      expect(find.text('Sát Thủ Về Hưu'), findsOneWidget);
    });

    testWidgets('Bấm nút "Bộ lọc" mở GenreBottomSheet thành công', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Nhấn nút "Bộ lọc"
      await tester.tap(find.text('Bộ lọc'));
      await tester.pumpAndSettle();

      // Kiểm tra modal bottom sheet mở lên
      final sheetFinder = find.byType(GenreBottomSheet);
      expect(sheetFinder, findsOneWidget);
      expect(find.descendant(of: sheetFinder, matching: find.text('Tất cả Thể loại & Bộ lọc')), findsOneWidget);
      expect(find.descendant(of: sheetFinder, matching: find.text('Trạng thái phát hành')), findsOneWidget);
      expect(find.descendant(of: sheetFinder, matching: find.text('Tất cả trạng thái')), findsOneWidget);
      expect(find.descendant(of: sheetFinder, matching: find.text('Đang tiến hành')), findsOneWidget);
      expect(find.descendant(of: sheetFinder, matching: find.text('Hoàn thành')), findsOneWidget);
      expect(find.descendant(of: sheetFinder, matching: find.text('Danh mục Thể loại')), findsOneWidget);
      expect(find.descendant(of: sheetFinder, matching: find.text('Áp dụng')), findsOneWidget);

      // Bấm nút "Áp dụng" để đóng
      await tester.tap(find.descendant(of: sheetFinder, matching: find.text('Áp dụng')));
      await tester.pumpAndSettle();

      expect(find.byType(GenreBottomSheet), findsNothing);
    });

    testWidgets('Lỗi tải thể loại trong GenreBottomSheet hiển thị JoyleeErrorView', (tester) async {
      await tester.pumpWidget(createWidget(genreError: true));
      await tester.pumpAndSettle();

      // Mở bottom sheet
      await tester.tap(find.text('Bộ lọc'));
      await tester.pumpAndSettle();

      // Hiển thị ErrorView trong phần thể loại
      expect(find.byType(JoyleeErrorView), findsOneWidget);
      expect(find.text('Không thể tải danh sách thể loại.'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  });
}
