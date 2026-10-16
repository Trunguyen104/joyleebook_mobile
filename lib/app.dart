import 'package:flutter/material.dart';
import 'ui/core/themes/app_theme.dart';
import 'ui/gateway_test/widgets/gateway_test_screen.dart';
import 'ui/series/widgets/series_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/core/themes/theme_provider.dart';

/// LỚP GỐC CỦA ỨNG DỤNG FLUTTER (JoyleeBookApp)
/// Cấu hình giao diện Material Design 3, màu sắc Warm Editorial,
/// và thanh điều hướng chuyển đổi giữa Trang Khám Phá Truyện và Trang Chẩn Đoán Gateway.
class JoyleeBookApp extends ConsumerStatefulWidget {
  const JoyleeBookApp({super.key});

  @override
  ConsumerState<JoyleeBookApp> createState() => _JoyleeBookAppState();
}

class _JoyleeBookAppState extends ConsumerState<JoyleeBookApp> {
  // Chỉ số tab đang chọn: 0 = Kho Truyện, 1 = Chẩn Đoán Gateway
  int _currentTabIndex = 0;

  // Danh sách các màn hình tương ứng với từng tab
  final List<Widget> _screens = const [
    SeriesListScreen(),   // Trang mẫu chức năng: Khám phá danh sách truyện
    GatewayTestScreen(),  // Trang kiểm tra: Gọi thử kết nối tới JoyleeBook Gateway
  ];

  @override
  Widget build(BuildContext context) {
    // Lang nghe trang thai themeMode tu Riverpod
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'JoyleeBook Mobile',
      debugShowCheckedModeBanner: false,
      // Áp dụng bộ màu chuẩn Warm Editorial cho cả chế độ Sáng và Tối
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      home: Scaffold(
        body: IndexedStack(
          index: _currentTabIndex,
          children: _screens,
        ),
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
