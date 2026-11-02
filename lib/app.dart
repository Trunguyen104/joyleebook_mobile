import 'package:flutter/material.dart';
import 'package:joyleebook_mobile/ui/bookmark/widgets/bookmark_screen.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/profile_screen.dart';

import 'ui/core/themes/app_theme.dart';
import 'ui/gateway_test/widgets/gateway_test_screen.dart';
import 'ui/series/widgets/series_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/services/api_client.dart';
import 'routing/app_paths.dart';
import 'routing/app_router.dart';
import 'ui/core/themes/app_theme.dart';
import 'ui/core/themes/theme_provider.dart';

/// Cho phép hiện SnackBar từ ngoài các màn hình (vd. khi phiên hết hạn)
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// LỚP GỐC CỦA ỨNG DỤNG FLUTTER (JoyleeBookApp)
/// Cấu hình giao diện Material Design 3, màu sắc Warm Editorial,
/// và thanh điều hướng giữa các khu vực dành cho độc giả.
class JoyleeBookApp extends ConsumerStatefulWidget {
  const JoyleeBookApp({super.key});

  @override
  ConsumerState<JoyleeBookApp> createState() => _JoyleeBookAppState();
}

class _JoyleeBookAppState extends ConsumerState<JoyleeBookApp> {
  // Chỉ số tab đang chọn: 0 = Kho Truyện, 1 = Tủ sách
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Lang nghe trang thai themeMode tu Riverpod
    final themeMode = ref.watch(themeModeProvider);
    final screens = [
      const SeriesListScreen(),
      BookmarkScreen(onExplore: () => setState(() => _currentTabIndex = 0)),
      const ProfileScreen(),
      const GatewayTestScreen(),
    ];

    return MaterialApp.router(
      title: 'JoyleeBook Mobile',
      debugShowCheckedModeBanner: false,
      // Áp dụng bộ màu chuẩn Warm Editorial cho cả chế độ Sáng và Tối
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      home: Scaffold(
        body: IndexedStack(index: _currentTabIndex, children: screens),
        // Thanh điều hướng đáy chuẩn Material 3 (NavigationBar)
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentTabIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded),
              label: 'Kho Truyện',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmarks_outlined),
              selectedIcon: Icon(Icons.bookmarks_rounded),
              label: 'Tủ sách',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
            NavigationDestination(
              icon: Icon(Icons.router_outlined),
              selectedIcon: Icon(Icons.router_rounded),
              label: 'Kiểm tra Gateway',
            ),
          ],
        ),
      ),
    );
  }
}
