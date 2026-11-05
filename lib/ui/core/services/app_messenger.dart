import 'package:flutter/material.dart';

/// Key dùng chung để hiện SnackBar từ ngoài cây widget (ví dụ thông báo realtime).
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
