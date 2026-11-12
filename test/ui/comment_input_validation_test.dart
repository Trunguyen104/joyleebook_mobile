import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/ui/comments/widgets/comment_input_box.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';

void main() {
  testWidgets('Chặn bình luận trắng và gửi nội dung đã trim', (tester) async {
    final submitted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CommentInputBox(
            isSignedIn: true,
            onSubmit: (text) async {
              submitted.add(text);
              return true;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(
      find.text(
        'Vui lòng nhập nội dung bình luận, không chỉ khoảng trắng hoặc xuống dòng.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    expect(submitted, isEmpty);
    await tester.enterText(find.byType(TextField), '  Hay quá!  ');
    await tester.pump();
    expect(
      find.text(
        'Vui lòng nhập nội dung bình luận, không chỉ khoảng trắng hoặc xuống dòng.',
      ),
      findsNothing,
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(submitted, ['Hay quá!']);
    expect(find.text('Vui lòng nhập nội dung bình luận.'), findsNothing);
  });

  testWidgets('Sửa bình luận: báo lỗi khi xóa hết và hết lỗi khi nhập lại', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CommentInputBox(
            isSignedIn: true,
            isEditing: true,
            initialText: 'Nội dung cũ',
            onSubmit: (_) async => true,
          ),
        ),
      ),
    );
    expect(find.text('Vui lòng nhập nội dung bình luận.'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Vui lòng nhập nội dung bình luận.'), findsOneWidget);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField), 'Nội dung mới');
    await tester.pump();
    expect(find.text('Vui lòng nhập nội dung bình luận.'), findsNothing);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNotNull,
    );
  });
}
