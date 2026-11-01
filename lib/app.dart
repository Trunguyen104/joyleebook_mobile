import 'package:flutter/material.dart';
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
/// và bộ định tuyến GoRouter (xem lib/routing/app_router.dart).
class JoyleeBookApp extends ConsumerWidget {
  const JoyleeBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lang nghe trang thai themeMode tu Riverpod
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    // Phiên hết hạn (refresh token thất bại): báo 1 lần rồi về màn Đăng nhập
    ref.listen(sessionExpiredProvider, (_, expired) {
      if (!expired) return;
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
        ),
      );
      router.go(AppPaths.signIn);
    });

    return MaterialApp.router(
      title: 'JoyleeBook Mobile',
      debugShowCheckedModeBanner: false,
      // Áp dụng bộ màu chuẩn Warm Editorial cho cả chế độ Sáng và Tối
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      routerConfig: router,
    );
  }
}
