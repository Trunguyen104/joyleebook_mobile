import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/app.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/chapter_repository.dart';
import 'package:joyleebook_mobile/data/repositories/payment_repository.dart';
import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/data/services/notification_socket_client.dart';
import 'package:joyleebook_mobile/domain/models/series.dart';
import 'package:joyleebook_mobile/ui/auth/widgets/sign_in_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_button.dart';
import 'package:joyleebook_mobile/ui/series/view_models/series_detail_view_model.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_detail_screen.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_rating_card.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_chapter_repository.dart';
import '../../testing/fakes/fake_notification_socket_client.dart';
import '../../testing/fakes/fake_payment_repository.dart';
import '../../testing/fakes/fake_profile_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';
import '../../testing/fakes/fake_token_storage.dart';

void main() {
  const testSeries = Series(
    id: 's_rating_1',
    title: 'Hành Trình Về Phương Đông',
    authorName: 'Nguyên Phong',
    description: 'Tác phẩm kinh điển về tâm linh và văn hóa phương Đông...',
    coverImageUrl: '',
    status: SeriesStatus.completed,
    genres: ['Tâm Linh'],
    isBookmarked: false,
    totalChapters: 5,
    averageRating: 0.0,
    totalRatings: 0,
    userRating: null,
  );

  group('SeriesDetailViewModel - Rate & Update Rating Business Logic', () {
    test(
      'Đánh giá lần đầu thành công: userRating được lưu, totalRatings tăng 1',
      () async {
        final fakeRepo = FakeSeriesRepository([testSeries]);
        final container = ProviderContainer(
          overrides: [seriesRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        // Đợi load initial state
        await container.read(
          seriesDetailViewModelProvider('s_rating_1').future,
        );

        final notifier = container.read(
          seriesDetailViewModelProvider('s_rating_1').notifier,
        );

        // Gửi đánh giá 5 sao
        final success = await notifier.rateSeries(5);
        expect(success, isTrue);

        final updated = container
            .read(seriesDetailViewModelProvider('s_rating_1'))
            .value!;
        expect(updated.userRating, equals(5));
        expect(updated.totalRatings, equals(1));
        expect(updated.averageRating, equals(5.0));
      },
    );

    test('Cập nhật đánh giá thành công: giữ nguyên totalRatings, tính lại averageRating', () async {
      const alreadyRatedSeries = Series(
        id: 's_rated',
        title: 'Truyện Đã Đánh Giá',
        authorName: 'Tác giả',
        description: 'Mô tả',
        coverImageUrl: '',
        status: SeriesStatus.ongoing,
        averageRating: 5.0,
        totalRatings: 1,
        userRating: 5,
      );

      final fakeRepo = FakeSeriesRepository([alreadyRatedSeries]);
      final container = ProviderContainer(
        overrides: [seriesRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(seriesDetailViewModelProvider('s_rated').future);
      final notifier = container.read(
        seriesDetailViewModelProvider('s_rated').notifier,
      );

      // Cập nhật từ 5 sao xuống 3 sao
      final success = await notifier.rateSeries(3);
      expect(success, isTrue);

      final updated = container
          .read(seriesDetailViewModelProvider('s_rated'))
          .value!;
      expect(updated.userRating, equals(3));
      expect(updated.totalRatings, equals(1)); // Không tăng thêm lượt
      expect(updated.averageRating, equals(3.0)); // Điểm trung bình cập nhật
    });

    test('Chặn giá trị điểm số âm (< 1) hoặc vượt quá 5 sao (Validation boundary check)', () async {
      final fakeRepo = FakeSeriesRepository([testSeries]);
      final container = ProviderContainer(
        overrides: [seriesRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      addTearDown(container.dispose);

      await container.read(seriesDetailViewModelProvider('s_rating_1').future);
      final notifier = container.read(
        seriesDetailViewModelProvider('s_rating_1').notifier,
      );

      // Điểm 0 -> Bị chặn
      final res0 = await notifier.rateSeries(0);
      expect(res0, isFalse);

      // Điểm âm -> Bị chặn
      final resNegative = await notifier.rateSeries(-1);
      expect(resNegative, isFalse);

      // Điểm 6 -> Bị chặn
      final res6 = await notifier.rateSeries(6);
      expect(res6, isFalse);

      // Dữ liệu ban đầu không bị ảnh hưởng
      final state = container
          .read(seriesDetailViewModelProvider('s_rating_1'))
          .value!;
      expect(state.userRating, isNull);
    });

    test(
      'Rollback tự động phục hồi state ban đầu khi API gặp sự cố mạng',
      () async {
        final fakeRepo = FakeSeriesRepository([testSeries], true); // Bật cờ lỗi
        final container = ProviderContainer(
          overrides: [seriesRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        addTearDown(container.dispose);

        // Đưa sẵn dữ liệu vào cache để build không bị lỗi ném ra từ FakeRepo
        final notifier = container.read(
          seriesDetailViewModelProvider('s_rating_1').notifier,
        );

        // Khi repo quăng lỗi
        final success = await notifier.rateSeries(4);
        expect(success, isFalse);

        // State phải rollback về null
        final state = container
            .read(seriesDetailViewModelProvider('s_rating_1'))
            .value;
        if (state != null) {
          expect(state.userRating, isNull);
        }
      },
    );
  });

  group('SeriesRatingCard & SeriesDetailScreen - Widget Tests', () {
    testWidgets('SeriesRatingCard hiển thị 5 nút sao và thông báo ban đầu', (
      tester,
    ) async {
      int? ratedScore;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SeriesRatingCard(
              userRating: null,
              averageRating: 0.0,
              totalRatings: 0,
              onRate: (score) async {
                ratedScore = score;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề và hàng sao
      expect(find.text('Đánh giá tác phẩm'), findsOneWidget);
      expect(find.text('Tác phẩm chưa có lượt đánh giá nào'), findsOneWidget);

      // Kiểm tra có đủ 5 nút sao
      expect(find.byKey(const Key('star_button_1')), findsOneWidget);
      expect(find.byKey(const Key('star_button_2')), findsOneWidget);
      expect(find.byKey(const Key('star_button_3')), findsOneWidget);
      expect(find.byKey(const Key('star_button_4')), findsOneWidget);
      expect(find.byKey(const Key('star_button_5')), findsOneWidget);

      // Bấm vào ngôi sao 5 để đánh giá trực tiếp
      await tester.tap(find.byKey(const Key('star_button_5')));
      await tester.pumpAndSettle();

      expect(ratedScore, equals(5));
    });

    testWidgets(
      'Chức năng Update Rating: Cập nhật trực tiếp bằng cách chọn số sao mới',
      (tester) async {
        int? updatedScore;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SeriesRatingCard(
                userRating: 4,
                averageRating: 4.0,
                totalRatings: 1,
                onRate: (score) async {
                  updatedScore = score;
                  return true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Trạng thái đã đánh giá
        expect(find.text('Đã đánh giá'), findsOneWidget);
        expect(
          find.text('Trung bình: 4.0 ★ (1 lượt đánh giá)'),
          findsOneWidget,
        );

        // Cập nhật trực tiếp: Bấm chọn sao 5 không cần nút chỉnh sửa/hủy
        await tester.tap(find.byKey(const Key('star_button_5')));
        await tester.pumpAndSettle();

        expect(updatedScore, equals(5));
      },
    );

    testWidgets(
      'Tích hợp SeriesDetailScreen: Khi chưa đăng nhập, bấm vào sao mở Dialog yêu cầu Đăng nhập',
      (tester) async {
        final fakeSeriesRepo = FakeSeriesRepository([testSeries]);
        final fakeChapterRepo = FakeChapterRepository([]);
        final fakeAuthRepo = FakeAuthRepository(
          savedSession: null,
        ); // Chưa đăng nhập

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              seriesRepositoryProvider.overrideWithValue(fakeSeriesRepo),
              chapterRepositoryProvider.overrideWithValue(fakeChapterRepo),
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              paymentRepositoryProvider.overrideWithValue(
                FakePaymentRepository(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const SeriesDetailScreen(seriesId: 's_rating_1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Kiểm tra badge hiển thị "Chưa có đánh giá" khi totalRatings == 0
        expect(find.text('Chưa có đánh giá'), findsOneWidget);

        // Cuộn để nút sao hiển thị trong tầm nhìn trước khi bấm
        await tester.ensureVisible(find.byKey(const Key('star_button_5')));
        await tester.pumpAndSettle();

        // Bấm vào ngôi sao 5 khi chưa đăng nhập
        await tester.tap(find.byKey(const Key('star_button_5')));
        await tester.pumpAndSettle();

        // Phải mở AlertDialog yêu cầu đăng nhập
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Đăng nhập để đánh giá'), findsOneWidget);
        expect(find.text('Đăng nhập ngay'), findsOneWidget);
        expect(find.text('Để sau'), findsOneWidget);
      },
    );

    testWidgets(
      'Tích hợp SeriesDetailScreen: Khi đã đăng nhập, thực hiện đánh giá mượt mà',
      (tester) async {
        final fakeSeriesRepo = FakeSeriesRepository([testSeries]);
        final fakeChapterRepo = FakeChapterRepository([]);
        final fakeAuthRepo = FakeAuthRepository(
          savedSession: fakeSession,
        ); // Đã đăng nhập

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              seriesRepositoryProvider.overrideWithValue(fakeSeriesRepo),
              chapterRepositoryProvider.overrideWithValue(fakeChapterRepo),
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              paymentRepositoryProvider.overrideWithValue(
                FakePaymentRepository(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: const SeriesDetailScreen(seriesId: 's_rating_1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Cuộn để nút sao hiển thị trong tầm nhìn trước khi bấm
        await tester.ensureVisible(find.byKey(const Key('star_button_5')));
        await tester.pumpAndSettle();

        // Tìm thấy SeriesRatingCard trong Tab Tóm tắt
        expect(find.byType(SeriesRatingCard), findsOneWidget);

        // Bấm đánh giá 5 sao
        await tester.tap(find.byKey(const Key('star_button_5')));
        await tester.pump(); // Optimistic update
        await tester.pumpAndSettle(); // Hoàn tất async

        // Xác nhận phản hồi thành công
        expect(find.text('5.0 (1)'), findsOneWidget);
      },
    );

    testWidgets(
      'Toàn bộ luồng: Đang ở Series Detail -> bấm đánh giá -> hiện popup -> đăng nhập -> quay lại đúng Series Detail -> đánh giá trực tiếp',
      (tester) async {
        final fakeSeriesRepo = FakeSeriesRepository([testSeries]);
        final fakeChapterRepo = FakeChapterRepository([]);
        final fakeAuthRepo = FakeAuthRepository(savedSession: null);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              seriesRepositoryProvider.overrideWithValue(fakeSeriesRepo),
              chapterRepositoryProvider.overrideWithValue(fakeChapterRepo),
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              profileRepositoryProvider.overrideWithValue(
                FakeProfileRepository(),
              ),
              tokenStorageProvider.overrideWithValue(
                FakeTokenStorage(accessToken: 'test-access-token'),
              ),
              notificationSocketClientProvider.overrideWithValue(
                FakeNotificationSocketClient(),
              ),
              paymentRepositoryProvider.overrideWithValue(
                FakePaymentRepository(),
              ),
            ],
            child: const JoyleeBookApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Ở Kho Truyện -> bấm vào truyện -> mở SeriesDetailScreen
        await tester.tap(find.text(testSeries.title));
        await tester.pumpAndSettle();
        expect(find.byType(SeriesDetailScreen), findsOneWidget);

        // Bấm vào sao 5 khi chưa đăng nhập
        await tester.ensureVisible(find.byKey(const Key('star_button_5')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('star_button_5')));
        await tester.pumpAndSettle();

        // Thấy dialog yêu cầu đăng nhập
        expect(find.text('Đăng nhập để đánh giá'), findsOneWidget);

        // Bấm "Đăng nhập ngay" -> chuyển sang màn hình Đăng nhập
        await tester.tap(find.text('Đăng nhập ngay'));
        await tester.pumpAndSettle();
        expect(find.byType(SignInScreen), findsOneWidget);

        // Nhập thông tin và Đăng nhập
        await tester.enterText(find.byType(TextField).at(0), 'demo.reader');
        await tester.enterText(
          find.byType(TextField).at(1),
          'DemoPassword123@',
        );
        await tester.tap(find.widgetWithText(JoyleeButton, 'Đăng nhập'));
        await tester.pumpAndSettle();

        // Tự động quay lại đúng màn hình SeriesDetailScreen
        expect(find.byType(SeriesDetailScreen), findsOneWidget);
        expect(find.byType(SignInScreen), findsNothing);

        // Đã đăng nhập -> Bấm đánh giá 5 sao
        await tester.ensureVisible(find.byKey(const Key('star_button_5')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('star_button_5')));
        await tester.pump(); // Optimistic update
        await tester.pumpAndSettle();

        // State thay đổi trực tiếp ngay trên giao diện
        expect(find.text('5.0 (1)'), findsOneWidget);
        expect(
          find.text('Trung bình: 5.0 ★ (1 lượt đánh giá)'),
          findsOneWidget,
        );
        expect(find.text('Đã đánh giá'), findsOneWidget);
      },
    );
  });
}
