import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications', style: textTheme.titleLarge),
        actions: [
          TextButton(
            onPressed: notifier.markAllRead,
            child: Text(
              'Mark all read',
              style: textTheme.bodySmall?.copyWith(color: cs.primary),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(child: Text('No notifications', style: textTheme.bodyMedium))
          : Builder(
              builder: (context) {
                final groups = _groupByDate(notifications).entries.toList();
                // Build a flat list: [header, card, card, header, card, ...]
                final items =
                    <
                      ({
                        bool isHeader,
                        String label,
                        AppNotification? notification,
                      })
                    >[];
                for (final entry in groups) {
                  items.add((
                    isHeader: true,
                    label: entry.key,
                    notification: null,
                  ));
                  for (final n in entry.value) {
                    items.add((isHeader: false, label: '', notification: n));
                  }
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item.isHeader) {
                      return _SectionHeader(label: item.label);
                    }
                    return _NotificationCard(
                      notification: item.notification!,
                      onTap: () => _onCardTap(context, ref, item.notification!),
                    );
                  },
                );
              },
            ),
    );
  }

  Map<String, List<AppNotification>> _groupByDate(
    List<AppNotification> notifications,
  ) {
    final now = DateTime.now();
    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];
    final earlier = <AppNotification>[];

    for (final n in notifications) {
      if (_isSameDay(n.timestamp, now)) {
        today.add(n);
      } else if (_isSameDay(
        n.timestamp,
        now.subtract(const Duration(days: 1)),
      )) {
        yesterday.add(n);
      } else {
        earlier.add(n);
      }
    }

    return {
      if (today.isNotEmpty) 'TODAY (${today.length})': today,
      if (yesterday.isNotEmpty) 'YESTERDAY (${yesterday.length})': yesterday,
      if (earlier.isNotEmpty) 'EARLIER (${earlier.length})': earlier,
    };
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onCardTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    ref.read(notificationsProvider.notifier).markRead(notification.id);
    if (notification.actionBatchId == null) return;
    switch (notification.type) {
      case NotificationType.deliverySuccessful:
      case NotificationType.deliveryArriving:
        context.push('/beneficiary/delivery/${notification.actionBatchId}');
      case NotificationType.matchConfirmed:
      case NotificationType.newBatch:
        context.push('/donor/batch/${notification.actionBatchId}/qr');
      default:
        break;
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Divider(color: cs.outlineVariant, thickness: 1)),
        ],
      ),
    );
  }
}

// ── Notification card ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationIcon(notification: notification),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    notification.body,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    _relativeTime(notification.timestamp),
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (notification.actionLabel != null &&
                      notification.actionBatchId != null) ...[
                    const SizedBox(height: Spacing.sm),
                    _ActionCard(notification: notification),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) {
      final h = timestamp.hour.toString().padLeft(2, '0');
      final m = timestamp.minute.toString().padLeft(2, '0');
      return 'yesterday at $h:$m';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${timestamp.day} ${months[timestamp.month - 1]}';
  }
}

// ── Notification icon with unread dot ─────────────────────────────────────────

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = Theme.of(context).extension<AppColors>()!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: notification.isRead
                ? cs.surfaceContainerHighest
                : cs.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _iconForType(notification.type),
            size: 20,
            color: notification.isRead ? cs.onSurfaceVariant : cs.onPrimary,
          ),
        ),
        if (!notification.isRead)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              key: ValueKey('unread_dot_${notification.id}'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ac.success,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconForType(NotificationType type) => switch (type) {
    NotificationType.newBatch => Icons.local_shipping_outlined,
    NotificationType.driverAssigned => Icons.directions_car_outlined,
    NotificationType.deliveryArriving => Icons.access_time_outlined,
    NotificationType.deliverySuccessful => Icons.check_circle_outline,
    NotificationType.batchCompleted => Icons.check_circle_outline,
    NotificationType.matchConfirmed => Icons.handshake_outlined,
  };
}

// ── Action card (e.g. "View Receipt") ─────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.receipt_long_outlined, color: cs.primary),
          ),
          const SizedBox(width: Spacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.actionLabel!,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Order #${notification.actionBatchId}',
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
