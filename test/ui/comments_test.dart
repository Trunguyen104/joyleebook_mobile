import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/comment_repository.dart';
import 'package:joyleebook_mobile/domain/models/chapter.dart';
import 'package:joyleebook_mobile/domain/models/comment.dart';
import 'package:joyleebook_mobile/ui/comments/widgets/comment_card.dart';
import 'package:joyleebook_mobile/ui/comments/widgets/comments_list_view.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_comment_repository.dart';

void main() {
  const dummyChapter = Chapter(
    id: 'chap-1',
    seriesId: 'series-1',
    sortOrder: 1,
    title: 'Chương 1: Khởi đầu',
  );

  testWidgets('Hiển thị JoyleeEmptyState khi danh sách bình luận rỗng', (
    tester,
  ) async {
    final fakeRepo = FakeCommentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(fakeRepo),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: CommentsListView(
              seriesId: 'series-1',
              availableChapters: [dummyChapter],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(JoyleeEmptyState), findsOneWidget);
    expect(find.text('Chưa có bình luận nào'), findsOneWidget);
  });

  testWidgets('Hiển thị danh sách bình luận khi có dữ liệu', (tester) async {
    final fakeRepo = FakeCommentRepository(
      initialComments: [
        Comment(
          id: 'c-1',
          seriesId: 'series-1',
          chapterId: 'chap-1',
          userId: 'user-other',
          username: 'doc_gia_vip',
          content: 'Tác phẩm rất lôi cuốn!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
          isEdited: false,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(fakeRepo),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: CommentsListView(
              seriesId: 'series-1',
              availableChapters: [dummyChapter],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CommentCard), findsOneWidget);
    expect(find.text('doc_gia_vip'), findsOneWidget);
    expect(find.text('Tác phẩm rất lôi cuốn!'), findsOneWidget);
  });

  testWidgets('Hiển thị yêu cầu đăng nhập khi chưa đăng nhập', (tester) async {
    final fakeRepo = FakeCommentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(fakeRepo),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(savedSession: null),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: CommentsListView(
              seriesId: 'series-1',
              availableChapters: [dummyChapter],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Đăng nhập để tham gia bình luận cùng độc giả khác.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);
  });

  testWidgets('Đã đăng nhập có thể gửi bình luận mới', (tester) async {
    final fakeRepo = FakeCommentRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentRepositoryProvider.overrideWithValue(fakeRepo),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(savedSession: fakeSession),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: CommentsListView(
              seriesId: 'series-1',
              availableChapters: [dummyChapter],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Nhập nội dung bình luận
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    await tester.enterText(textField, 'Bình luận kiểm thử từ test!');
    await tester.pump();

    // Bấm nút gửi
    final sendButton = find.byTooltip('Gửi bình luận');
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    // Bình luận mới xuất hiện trong danh sách
    expect(find.byType(CommentCard), findsOneWidget);
    expect(find.text('Bình luận kiểm thử từ test!'), findsOneWidget);
  });
}
