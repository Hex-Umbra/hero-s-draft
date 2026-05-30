import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationType {
  info,
  success,
  error,
  warning,
}

class GameNotification {
  final String id;
  final String message;
  final NotificationType type;
  final DateTime timestamp;

  GameNotification({
    required this.id,
    required this.message,
    this.type = NotificationType.info,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationNotifier extends StateNotifier<List<GameNotification>> {
  final Map<String, Timer> _timers = {};

  NotificationNotifier() : super([]);

  void show(String message, {NotificationType type = NotificationType.info}) {
    final notification = GameNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      message: message,
      type: type,
    );
    // Supprime la plus ancienne si le stack dépasse 4 notifications actives
    if (state.length >= 4) {
      state = [...state.sublist(1), notification];
    } else {
      state = [...state, notification];
    }

    _timers[notification.id]?.cancel();

    // Auto-suppression après 3,5 secondes
    _timers[notification.id] = Timer(const Duration(milliseconds: 3500), () {
      dismiss(notification.id);
    });
  }

  void dismiss(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    state = [];
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<GameNotification>>((ref) {
  return NotificationNotifier();
});

extension NotificationContextExtension on BuildContext {
  void showNotification(String message, {NotificationType type = NotificationType.info}) {
    try {
      ProviderScope.containerOf(this, listen: false)
          .read(notificationProvider.notifier)
          .show(message, type: type);
    } catch (e) {
      debugPrint("Notification: $message (Type: $type)");
    }
  }
}

class GameNotificationOverlay extends ConsumerStatefulWidget {
  const GameNotificationOverlay({super.key});

  @override
  ConsumerState<GameNotificationOverlay> createState() => _GameNotificationOverlayState();
}

class _GameNotificationOverlayState extends ConsumerState<GameNotificationOverlay> {
  @override
  void dispose() {
    // Annule tous les Timers restants et nettoie le cache lors du démontage du widget (indispensable pour les tests)
    ref.read(notificationProvider.notifier).clearAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);

    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 20,
      top: 0,
      bottom: 0,
      child: Center(
        child: SizedBox(
          width: 300,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: notifications.map((n) {
                return Padding(
                  key: ValueKey(n.id),
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: _AnimatedNotificationTile(notification: n),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedNotificationTile extends StatefulWidget {
  final GameNotification notification;

  const _AnimatedNotificationTile({required this.notification});

  @override
  State<_AnimatedNotificationTile> createState() => _AnimatedNotificationTileState();
}

class _AnimatedNotificationTileState extends State<_AnimatedNotificationTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;

    Color color;
    IconData icon;
    switch (n.type) {
      case NotificationType.success:
        color = const Color(0xFF34C759); // Vert premium
        icon = Icons.check_circle_outline_rounded;
        break;
      case NotificationType.error:
        color = const Color(0xFFFF3B30); // Rouge premium
        icon = Icons.error_outline_rounded;
        break;
      case NotificationType.warning:
        color = const Color(0xFFFFCC00); // Jaune or premium
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.info:
        color = const Color(0xFF007AFF); // Bleu premium
        icon = Icons.info_outline_rounded;
        break;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * 300, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: color,
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 12.0, bottom: 12.0),
                  child: Text(
                    n.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
