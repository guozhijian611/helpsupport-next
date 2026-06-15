import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

OverlayEntry? _activeNoticeEntry;
Timer? _activeNoticeTimer;

void showAppCenteredNotice(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  final text = message.trim();
  if (text.isEmpty) {
    return;
  }

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  void present() {
    _activeNoticeTimer?.cancel();
    _activeNoticeEntry?.remove();

    if (overlay == null) {
      if (messenger == null) {
        return;
      }
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            content: Text(text, textAlign: TextAlign.center),
          ),
        );
      return;
    }

    final entry = OverlayEntry(
      builder: (context) =>
          _CenteredNoticeOverlay(message: text, textStyle: textStyle),
    );
    overlay.insert(entry);
    _activeNoticeEntry = entry;
    _activeNoticeTimer = Timer(duration, () {
      if (identical(_activeNoticeEntry, entry)) {
        entry.remove();
        _activeNoticeEntry = null;
        _activeNoticeTimer = null;
      }
    });
  }

  if (SchedulerBinding.instance.schedulerPhase ==
      SchedulerPhase.persistentCallbacks) {
    WidgetsBinding.instance.addPostFrameCallback((_) => present());
    return;
  }
  present();
}

extension CenteredNoticeBuildContext on BuildContext {
  void showCenteredNotice(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showAppCenteredNotice(this, message, duration: duration);
  }
}

class _CenteredNoticeOverlay extends StatelessWidget {
  const _CenteredNoticeOverlay({required this.message, this.textStyle});

  final String message;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xE61F1F1F),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: textStyle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
