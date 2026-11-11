import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/data/repositories/auth_repository.dart';
import 'package:joyleebook_mobile/data/repositories/genre_repository.dart';
import 'package:joyleebook_mobile/data/repositories/notification_repository.dart';
import 'package:joyleebook_mobile/data/repositories/payment_repository.dart';
import 'package:joyleebook_mobile/data/repositories/profile_repository.dart';
import 'package:joyleebook_mobile/data/repositories/series_repository.dart';
import 'package:joyleebook_mobile/domain/models/app_notification.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/bookmark_screen.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_theme.dart';
import 'package:joyleebook_mobile/ui/notifications/widgets/notification_bell_button.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/profile_screen.dart';
import 'package:joyleebook_mobile/ui/search/widgets/search_screen.dart';
import 'package:joyleebook_mobile/ui/series/widgets/series_list_screen.dart';

import '../../testing/fakes/fake_auth_repository.dart';
import '../../testing/fakes/fake_genre_repository.dart';
import '../../testing/fakes/fake_notification_repository.dart';
import '../../testing/fakes/fake_payment_repository.dart';
import '../../testing/fakes/fake_profile_repository.dart';
import '../../testing/fakes/fake_series_repository.dart';

void main() {
  final notifRepo = FakeNotificationRepository(
    items: [
      AppNotification(
        id: 'n1',
        userId: fakeSession.userId,
        type: 0,
        title: 'Thông báo 1',
        message: 'Nội dung',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
  );

  Widget buildTestApp(Widget child) => ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(savedSession: fakeSession),
      ),
      notificationRepositoryProvider.overrideWithValue(notifRepo),
      seriesRepositoryProvider.overrideWithValue(FakeSeriesRepository([])),
      genreRepositoryProvider.overrideWithValue(FakeGenreRepository()),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
      paymentRepositoryProvider.overrideWithValue(FakePaymentRepository()),
    ],
    child: MaterialApp(theme: AppTheme.light, home: child),
  );

  testWidgets('SeriesListScreen có NotificationBellButton trên AppBar', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp(const SeriesListScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationBellButton), findsOneWidget);
  });

  testWidgets('BookmarkScreen có NotificationBellButton trên AppBar', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp(const BookmarkScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationBellButton), findsOneWidget);
  });

  testWidgets('SearchScreen có NotificationBellButton trên AppBar', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp(const SearchScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationBellButton), findsOneWidget);
  });

  testWidgets(
    'ProfileScreen KHÔNG có NotificationBellButton trên AppBar (ẩn khi vào cá nhân)',
    (tester) async {
      await tester.pumpWidget(buildTestApp(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationBellButton), findsNothing);
    },
  );
}
