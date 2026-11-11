import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/models/downloaded_series.dart';
import '../domain/models/series.dart';
import '../ui/auth/view_models/auth_session_view_model.dart';
import '../ui/auth/widgets/forgot_password_screen.dart';
import '../ui/auth/widgets/change_password_screen.dart';
import '../ui/auth/widgets/reset_password_screen.dart';
import '../ui/auth/widgets/sign_in_screen.dart';
import '../ui/auth/widgets/sign_up_screen.dart';
import '../ui/bookmark/widgets/bookmark_screen.dart';
import '../ui/bookmark/widgets/bookmark_list_screen.dart';
import '../ui/bookmark/widgets/reading_history_screen.dart';
import '../ui/download/widgets/downloaded_series_screen.dart';
import '../ui/download/widgets/offline_series_detail_screen.dart';
import '../ui/chapter/widgets/chapter_detail_screen.dart';
import '../ui/chapter/widgets/chapter_list_screen.dart';
import '../ui/gateway_test/widgets/gateway_test_screen.dart';
import '../ui/notifications/widgets/notification_screen.dart';
import '../ui/profile/widgets/edit_profile_screen.dart';
import '../ui/profile/widgets/profile_screen.dart';
import '../ui/profile/widgets/settings_screen.dart';
import '../ui/wallet/widgets/wallet_screen.dart';
import '../ui/search/widgets/search_screen.dart';
import '../ui/series/widgets/series_detail_screen.dart';
import '../ui/series/widgets/series_list_screen.dart';
import 'app_paths.dart';
import 'app_shell.dart';

/// Các trang bắt buộc đăng nhập. Kho Truyện xem được khi chưa đăng nhập.
const _authPaths = {
  AppPaths.signIn,
  AppPaths.signUp,
  AppPaths.forgotPassword,
  AppPaths.resetPassword,
};

bool _isPrivatePath(String path) =>
    path == AppPaths.profile ||
    path.startsWith('${AppPaths.profile}/') ||
    path == AppPaths.bookmarks ||
    path.startsWith('${AppPaths.bookmarks}/') ||
    path == AppPaths.notifications ||
    path.startsWith('${AppPaths.notifications}/');

/// Navigator gốc (nằm trên thanh tab). Trang nào gắn key này sẽ mở toàn màn hình.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// BỘ ĐỊNH TUYẾN CỦA APP
/// - 5 tab giữ nguyên trạng thái khi chuyển tab (Kho Truyện, Khám Phá, Tủ Sách, Thông Báo, Cá Nhân).
/// - Chi tiết truyện và danh sách chương mở bên trong tab Kho Truyện (vẫn thấy thanh tab).
/// - Trang đọc chương, /sign-in, /sign-up mở toàn màn hình, không có thanh tab.
/// - [redirect] là nơi DUY NHẤT quyết định "chưa đăng nhập thì đi đâu".
///
/// Dữ liệu truyền kèm khi mở trang (`extra`) chỉ để hiện nhanh, không bắt buộc:
/// - Chi tiết truyện: `Series` vừa bấm, để hiện ngay trong lúc tải bản mới nhất.
/// - Danh sách chương, trang đọc: tên bộ truyện (`String`) để hiện trên AppBar.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Mỗi khi phiên đăng nhập thay đổi -> báo GoRouter chạy lại redirect
  final authChanged = ValueNotifier<int>(0);
  ref.listen(authSessionProvider, (_, _) => authChanged.value++);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppPaths.series,
    refreshListenable: authChanged,
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      // Đang đọc token đã lưu khi mở app -> chưa quyết định gì
      if (session.isLoading) return null;

      final isSignedIn = session.value != null;
      final path = state.matchedLocation;

      if (!isSignedIn && _isPrivatePath(path)) {
        final from = path == AppPaths.changePassword ? AppPaths.profile : path;
        return '${AppPaths.signIn}?from=$from';
      }
      if (isSignedIn && _authPaths.contains(path)) {
        return state.uri.queryParameters['from'] ?? AppPaths.series;
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // TAB 0: KHO TRUYỆN (HOME FEED)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppPaths.series,
                builder: (context, state) => const SeriesListScreen(),
                routes: [
                  // /series/:seriesId
                  GoRoute(
                    path: ':seriesId',
                    builder: (context, state) => SeriesDetailScreen(
                      seriesId: state.pathParameters['seriesId']!,
                      initialSeries: state.extra as Series?,
                    ),
                    routes: [
                      // /series/:seriesId/chapters
                      GoRoute(
                        path: 'chapters',
                        builder: (context, state) => ChapterListScreen(
                          seriesId: state.pathParameters['seriesId']!,
                          seriesTitle: state.extra as String? ?? '',
                        ),
                        routes: [
                          // /series/:seriesId/chapters/:chapterId
                          GoRoute(
                            path: ':chapterId',
                            // Trang đọc mở toàn màn hình để tập trung đọc
                            parentNavigatorKey: _rootNavigatorKey,
                            builder: (context, state) => ChapterDetailScreen(
                              seriesId: state.pathParameters['seriesId']!,
                              chapterId: state.pathParameters['chapterId']!,
                              seriesTitle: state.extra as String? ?? '',
                              isOfflineMode:
                                  state.uri.queryParameters['offline'] == '1',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // TAB 1: KHÁM PHÁ & TÌM KIẾM (SEARCH & GENRE FILTERS)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppPaths.search,
                builder: (context, state) => SearchScreen(
                  initialGenre: state.uri.queryParameters['genre'],
                ),
              ),
            ],
          ),

          // TAB 2: TỦ SÁCH (BOOKMARKS)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppPaths.bookmarks,
                builder: (context, state) => BookmarkScreen(
                  onExplore: () => context.go(AppPaths.search),
                ),
                routes: [
                  GoRoute(
                    path: 'all',
                    builder: (context, state) => BookmarkListScreen(
                      onExplore: () => context.go(AppPaths.series),
                    ),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => ReadingHistoryScreen(
                      onExplore: () => context.go(AppPaths.series),
                    ),
                  ),
                  GoRoute(
                    path: 'downloads',
                    builder: (context, state) => DownloadedSeriesScreen(
                      onExplore: () => context.go(AppPaths.series),
                    ),
                    routes: [
                      GoRoute(
                        path: ':seriesId',
                        builder: (context, state) {
                          final seriesId = state.pathParameters['seriesId']!;
                          final extra = state.extra;
                          return OfflineSeriesDetailScreen(
                            seriesId: seriesId,
                            initialSeries: extra is DownloadedSeries
                                ? extra
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // TAB 3: TRANG CÁ NHÂN (PROFILE)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppPaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppPaths.notifications,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: AppPaths.gateway,
        builder: (context, state) => const GatewayTestScreen(),
      ),
      GoRoute(
        path: AppPaths.signIn,
        builder: (context, state) =>
            SignInScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: AppPaths.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppPaths.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppPaths.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: AppPaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppPaths.signUp,
        builder: (context, state) =>
            SignUpScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: AppPaths.forgotPassword,
        builder: (context, state) =>
            ForgotPasswordScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: AppPaths.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
          token: state.uri.queryParameters['token'] ?? '',
          from: state.uri.queryParameters['from'],
        ),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authChanged.dispose();
  });
  return router;
});
