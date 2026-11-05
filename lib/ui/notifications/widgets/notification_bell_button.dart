import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/view_models/auth_session_view_model.dart';
import '../../core/widgets/joylee_notification_bell.dart';
import '../view_models/notification_feed_view_model.dart';
import 'notification_popup.dart';

class NotificationBellButton extends ConsumerStatefulWidget {
  const NotificationBellButton({super.key});

  @override
  ConsumerState<NotificationBellButton> createState() =>
      _NotificationBellButtonState();
}

class _NotificationBellButtonState
    extends ConsumerState<NotificationBellButton> {
  final GlobalKey _bellKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggle() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    final media = MediaQuery.of(context);
    final bellBox = _bellKey.currentContext?.findRenderObject();
    final bellBottom = bellBox is RenderBox
        ? bellBox.localToGlobal(Offset.zero).dy + bellBox.size.height
        : media.padding.top + kToolbarHeight;
    final top = bellBottom + 8;
    final availableHeight =
        media.size.height -
        top -
        media.padding.bottom -
        media.viewInsets.bottom -
        12;
    final width = math.min(340.0, media.size.width - 24);
    final maxHeight = math.min(420.0, math.max(0.0, availableHeight));

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: ModalBarrier(
              color: const Color(0x14000000),
              dismissible: true,
              onDismiss: _removeOverlay,
            ),
          ),
          Positioned(
            top: top,
            right: 12,
            child: SizedBox(
              width: width,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, -8 * (1 - value)),
                    child: child,
                  ),
                ),
                child: NotificationPopup(
                  maxHeight: maxHeight,
                  onClose: _removeOverlay,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    final entry = _overlayEntry;
    _overlayEntry = null;
    entry?.remove();
    entry?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (_, next) {
      if (next.value == null) _removeOverlay();
    });

    final session = ref.watch(authSessionProvider);
    if (session.value == null) return const SizedBox.shrink();

    final unreadCount =
        ref.watch(notificationFeedViewModelProvider).value?.unreadCount ?? 0;

    return JoyleeNotificationBell(
      key: _bellKey,
      unreadCount: unreadCount,
      onPressed: _toggle,
    );
  }
}
