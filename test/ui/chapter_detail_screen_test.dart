import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/ui/chapter/widgets/chapter_detail_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_chapter_repository.dart';

void main() {
  const screen = ChapterDetailScreen(
    seriesId: '1',
    chapterId: 'ch-1',
    seriesTitle: 'Truyện thử nghiệm',
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chapterRepositoryProvider.overrideWithValue(FakeChapterRepository()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Offset headerOffset(WidgetTester tester) {
    return tester
        .widget<AnimatedSlide>(find.byKey(const Key('chapter-reader-header')))
        .offset;
  }

  Offset footerOffset(WidgetTester tester) {
    return tester
        .widget<AnimatedSlide>(find.byKey(const Key('chapter-reader-footer')))
        .offset;
  }

  testWidgets('Chạm vào nội dung sẽ ẩn rồi hiện lại header và footer', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(headerOffset(tester), Offset.zero);
    expect(footerOffset(tester), Offset.zero);

    // Chạm vào vùng nội dung đọc -> ẩn header & footer
    await tester.tap(find.text('Nội dung đọc thử nghiệm...'));
    await tester.pumpAndSettle();

    expect(headerOffset(tester), const Offset(0, -1));
    expect(footerOffset(tester), const Offset(0, 1));

    // Chạm lần nữa -> hiện lại header & footer
    await tester.tap(find.text('Nội dung đọc thử nghiệm...'));
    await tester.pumpAndSettle();

    expect(headerOffset(tester), Offset.zero);
    expect(footerOffset(tester), Offset.zero);
  });
}
