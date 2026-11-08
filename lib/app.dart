import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/services/api_client.dart';
import 'routing/app_router.dart';
import 'ui/core/services/app_messenger.dart';
import 'ui/core/themes/app_theme.dart';
import 'ui/core/themes/theme_provider.dart';
import 'ui/notifications/view_models/notification_realtime_view_model.dart';
import 'ui/notifications/widgets/notification_realtime_listener.dart';

/// LỚP GỐC CỦA ỨNG DỤNG FLUTTER (JoyleeBookApp)
/// Cấu hình giao diện Material Design 3, màu sắc Warm Editorial,
/// và thanh điều hướng giữa các khu vực dành cho độc giả.
class JoyleeBookApp extends ConsumerStatefulWidget {
  const JoyleeBookApp({super.key});

  @override
  ConsumerState<JoyleeBookApp> createState() => _JoyleeBookAppState();
}

class _JoyleeBookAppState extends ConsumerState<JoyleeBookApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationRealtimeViewModelProvider.notifier).restart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    ref.listen<bool>(sessionExpiredProvider, (previous, expired) {
      if (expired) {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            ),
          ),
        );
      }
    });

    return NotificationRealtimeListener(
      child: MaterialApp.router(
        title: 'JoyleeBook Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        themeAnimationDuration: Duration.zero,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        routerConfig: router,
      ),
    );
  }
}
