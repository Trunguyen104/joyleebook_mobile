import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/services/api_client.dart';
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
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    ref.listen<bool>(sessionExpiredProvider, (previous, expired) {
      if (expired) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            ),
          ),
        );
      }
    });

    return MaterialApp.router(
      title: 'JoyleeBook Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      routerConfig: router,
    );
  }
}
