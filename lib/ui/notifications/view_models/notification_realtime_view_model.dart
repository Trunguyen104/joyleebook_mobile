import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/api_endpoints.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/notification_socket_client.dart';
import '../../../domain/models/app_notification.dart';
import '../../auth/view_models/auth_session_view_model.dart';
import 'notification_feed_view_model.dart';

enum NotificationRealtimeStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

@immutable
class NotificationRealtimeState {
  final NotificationRealtimeStatus status;
  final AppNotification? lastIncoming;

  const NotificationRealtimeState({
    required this.status,
    this.lastIncoming,
  });

  const NotificationRealtimeState.disconnected()
    : status = NotificationRealtimeStatus.disconnected,
      lastIncoming = null;

  NotificationRealtimeState copyWith({
    NotificationRealtimeStatus? status,
    AppNotification? lastIncoming,
  }) {
    return NotificationRealtimeState(
      status: status ?? this.status,
      lastIncoming: lastIncoming ?? this.lastIncoming,
    );
  }
}

final notificationRealtimeViewModelProvider =
    NotifierProvider<NotificationRealtimeViewModel, NotificationRealtimeState>(
      NotificationRealtimeViewModel.new,
    );

class NotificationRealtimeViewModel
    extends Notifier<NotificationRealtimeState> {
  static const _retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  final LinkedHashSet<String> _shownIds = LinkedHashSet<String>();
  Timer? _retryTimer;
  int _retryAttempt = 0;
  int _generation = 0;

  @override
  NotificationRealtimeState build() {
    final session = ref.watch(authSessionProvider).value;
    final baseUrl = ref.watch(gatewayBaseUrlProvider);
    final client = ref.watch(notificationSocketClientProvider);

    _retryTimer?.cancel();
    _retryTimer = null;
    _retryAttempt = 0;
    _shownIds.clear();
    final generation = ++_generation;

    ref.onDispose(() {
      _retryTimer?.cancel();
      unawaited(client.disconnect());
    });

    if (session == null) {
      unawaited(client.disconnect());
      return const NotificationRealtimeState.disconnected();
    }

    unawaited(_connect(generation, client, _hubUrl(baseUrl)));
    return const NotificationRealtimeState(
      status: NotificationRealtimeStatus.connecting,
    );
  }

  /// Gọi khi app quay lại foreground để chắc chắn socket còn sống.
  void restart() {
    if (ref.read(authSessionProvider).value == null) return;
    ref.invalidateSelf();
  }

  Future<void> _connect(
    int generation,
    NotificationSocketClient client,
    String hubUrl,
  ) async {
    final token = await ref.read(tokenStorageProvider).readAccessToken();
    if (generation != _generation) return;
    if (token == null || token.isEmpty) {
      state = const NotificationRealtimeState.disconnected();
      return;
    }

    try {
      await client.connect(
        hubUrl: hubUrl,
        accessTokenFactory: () =>
            ref.read(tokenStorageProvider).readAccessToken(),
        onNotification: _handleIncoming,
        onClosed: () => _handleClosed(generation, client, hubUrl),
      );
      if (generation != _generation) return;
      _retryAttempt = 0;
      state = state.copyWith(status: NotificationRealtimeStatus.connected);
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(status: NotificationRealtimeStatus.error);
      _scheduleReconnect(generation, client, hubUrl);
    }
  }

  void _handleClosed(
    int generation,
    NotificationSocketClient client,
    String hubUrl,
  ) {
    if (generation != _generation) return;
    state = state.copyWith(status: NotificationRealtimeStatus.reconnecting);
    _scheduleReconnect(generation, client, hubUrl);
  }

  void _scheduleReconnect(
    int generation,
    NotificationSocketClient client,
    String hubUrl,
  ) {
    if (generation != _generation) return;
    _retryTimer?.cancel();

    final index = _retryAttempt < _retryDelays.length
        ? _retryAttempt
        : _retryDelays.length - 1;
    final delay = _retryDelays[index];
    _retryAttempt++;

    _retryTimer = Timer(delay, () {
      if (generation != _generation) return;
      unawaited(_connect(generation, client, hubUrl));
    });
  }

  void _handleIncoming(AppNotification notification) {
    if (ref.read(authSessionProvider).value == null) return;

    ref
        .read(notificationFeedViewModelProvider.notifier)
        .receiveRealtime(notification);

    if (!_shownIds.add(notification.id)) return;
    if (_shownIds.length > 100) _shownIds.remove(_shownIds.first);
    state = state.copyWith(lastIncoming: notification);
  }

  String _hubUrl(String baseUrl) {
    var trimmed = baseUrl.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return '$trimmed${ApiEndpoints.notificationsHub}';
  }
}
