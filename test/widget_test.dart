// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/app.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import '../testing/fakes/fake_series_repository.dart';

void main() {
  testWidgets('JoyleeBookApp render và chuyển đổi tab thành công', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(FakeSeriesRepository([])),
        ],
        child: const JoyleeBookApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tab 0 mặc định là Kho Truyện
    expect(find.text('Kho Truyện JoyleeBook'), findsOneWidget);
    expect(find.text('Kho Truyện'), findsOneWidget);
    expect(find.text('Kiểm tra Gateway'), findsOneWidget);

    // Chuyển sang Tab 1: Kiểm tra Gateway
    await tester.tap(find.text('Kiểm tra Gateway'));
    await tester.pumpAndSettle();

    expect(find.text('Kiểm tra Kết nối Gateway'), findsOneWidget);
    expect(find.text('Bắt đầu Kiểm tra Kết nối'), findsOneWidget);
  });
}
