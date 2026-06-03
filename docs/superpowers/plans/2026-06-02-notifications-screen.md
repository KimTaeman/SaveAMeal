# Notifications Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a shared `/notifications` screen with date-grouped notification cards, unread dot indicators, and mark-as-read actions, wired to all three role dashboards.

**Architecture:** Clean Architecture stubs — `AppNotification` entity in domain, `MockNotificationsRepository` in data (swap-ready for Firestore), `NotificationsNotifier` Riverpod provider in presentation. Single shared `/notifications` GoRouter route at the root level.

**Tech Stack:** Flutter, Riverpod (riverpod_annotation codegen), Freezed, GoRouter, flutter_test

---

## File Map

| Action | Path |
|--------|------|
| Create | `lib/features/notifications/domain/entities/app_notification.dart` |
| Create | `lib/features/notifications/domain/repositories/notifications_repository.dart` |
| Create | `lib/features/notifications/data/repositories/mock_notifications_repository.dart` |
| Create | `lib/features/notifications/presentation/providers/notifications_provider.dart` |
| Create | `lib/features/notifications/presentation/screens/notifications_screen.dart` |
| Create | `test/widget/notifications_screen_test.dart` |
| Modify | `lib/app/router.dart` |
| Modify | `lib/features/donor/presentation/screens/donor_dashboard_screen.dart` |
| Modify | `lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart` |
| Modify | `lib/features/driver/presentation/screens/driver_map_screen.dart` |
| Modify | `lib/features/driver/presentation/screens/claim_rescue_screen.dart` |

> All paths are relative to `apps/mobile/`. Run all commands from `apps/mobile/`.

---

## Task 1: AppNotification entity

**Files:**
- Create: `lib/features/notifications/domain/entities/app_notification.dart`

- [ ] **Step 1: Create the entity file**

```dart
// lib/features/notifications/domain/entities/app_notification.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

enum NotificationType {
  newBatch,
  driverAssigned,
  deliveryArriving,
  deliverySuccessful,
  batchCompleted,
  matchConfirmed,
}

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationType type,
    required String title,
    required String body,
    required DateTime timestamp,
    required bool isRead,
    String? actionLabel,
    String? actionBatchId,
  }) = _AppNotification;
}
```

- [ ] **Step 2: Run build_runner to generate the Freezed file**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: a new file `lib/features/notifications/domain/entities/app_notification.freezed.dart` is generated with no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/notifications/domain/entities/
git commit -m "feat(notifications): add AppNotification entity"
```

---

## Task 2: Repository interface + mock

**Files:**
- Create: `lib/features/notifications/domain/repositories/notifications_repository.dart`
- Create: `lib/features/notifications/data/repositories/mock_notifications_repository.dart`

- [ ] **Step 1: Create the repository interface**

```dart
// lib/features/notifications/domain/repositories/notifications_repository.dart
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationsRepository {
  List<AppNotification> getAll();
  void markRead(String id);
  void markAllRead();
}
```

- [ ] **Step 2: Create the mock repository with seeded data**

```dart
// lib/features/notifications/data/repositories/mock_notifications_repository.dart
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';

class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    _items = [
      AppNotification(
        id: '1',
        type: NotificationType.deliveryArriving,
        title: 'Driver Arriving Soon',
        body: 'Nattapong is 5 minutes away with your delivery.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      AppNotification(
        id: '2',
        type: NotificationType.matchConfirmed,
        title: 'Match Confirmed! Batch #8492 is assigned to Haven Shelter.',
        body: 'Driver on the way.',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      AppNotification(
        id: '3',
        type: NotificationType.deliverySuccessful,
        title: 'Delivery Successful! Haven Shelter received your bakery batch.',
        body: 'You saved 37.5kg of CO2!',
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: true,
      ),
      AppNotification(
        id: '4',
        type: NotificationType.deliverySuccessful,
        title: 'Delivery Successful',
        body: '38 portions of bakery goods were dropped off by Nattapong.',
        timestamp: yesterday.copyWith(hour: 14, minute: 45),
        isRead: true,
        actionLabel: 'View Receipt',
        actionBatchId: '8832',
      ),
      AppNotification(
        id: '5',
        type: NotificationType.batchCompleted,
        title: 'Batch #8411 Completed.',
        body: 'Your batch has been completed successfully.',
        timestamp: yesterday.copyWith(hour: 10, minute: 0),
        isRead: true,
      ),
    ];
  }

  late List<AppNotification> _items;

  @override
  List<AppNotification> getAll() => List.unmodifiable(_items);

  @override
  void markRead(String id) =>
      _items = _items
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();

  @override
  void markAllRead() =>
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/notifications/
git commit -m "feat(notifications): add NotificationsRepository interface and mock"
```

---

## Task 3: Riverpod provider

**Files:**
- Create: `lib/features/notifications/presentation/providers/notifications_provider.dart`

- [ ] **Step 1: Create the provider file**

```dart
// lib/features/notifications/presentation/providers/notifications_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/notifications/data/repositories/mock_notifications_repository.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';

part 'notifications_provider.g.dart';

@riverpod
NotificationsRepository notificationsRepository(Ref ref) =>
    MockNotificationsRepository();

@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  List<AppNotification> build() =>
      ref.read(notificationsRepositoryProvider).getAll();

  void markRead(String id) {
    ref.read(notificationsRepositoryProvider).markRead(id);
    state = ref.read(notificationsRepositoryProvider).getAll();
  }

  void markAllRead() {
    ref.read(notificationsRepositoryProvider).markAllRead();
    state = ref.read(notificationsRepositoryProvider).getAll();
  }
}
```

- [ ] **Step 2: Run build_runner**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `lib/features/notifications/presentation/providers/notifications_provider.g.dart` is generated.

- [ ] **Step 3: Commit**

```bash
git add lib/features/notifications/presentation/providers/
git commit -m "feat(notifications): add NotificationsNotifier provider"
```

---

## Task 4: Widget tests (write failing)

**Files:**
- Create: `test/widget/notifications_screen_test.dart`

- [ ] **Step 1: Create the test file**

```dart
// test/widget/notifications_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/notifications/domain/entities/app_notification.dart';
import 'package:saveameal/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:saveameal/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:saveameal/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:saveameal/shared/theme/app_colors.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeNotificationsRepository implements NotificationsRepository {
  _FakeNotificationsRepository(List<AppNotification> items)
      : _items = List.of(items);
  List<AppNotification> _items;

  @override
  List<AppNotification> getAll() => List.unmodifiable(_items);

  @override
  void markRead(String id) =>
      _items = _items
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();

  @override
  void markAllRead() =>
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
}

// ── Seed data ─────────────────────────────────────────────────────────────────

List<AppNotification> _seedNotifications() {
  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));
  return [
    AppNotification(
      id: '1',
      type: NotificationType.deliveryArriving,
      title: 'Driver Arriving Soon',
      body: 'Driver is 5 minutes away.',
      timestamp: now.subtract(const Duration(minutes: 15)),
      isRead: false,
    ),
    AppNotification(
      id: '2',
      type: NotificationType.matchConfirmed,
      title: 'Match Confirmed',
      body: 'Batch assigned.',
      timestamp: now.subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    AppNotification(
      id: '3',
      type: NotificationType.deliverySuccessful,
      title: 'Delivery Successful',
      body: 'Batch delivered today.',
      timestamp: now.subtract(const Duration(hours: 1)),
      isRead: true,
    ),
    AppNotification(
      id: '4',
      type: NotificationType.deliverySuccessful,
      title: 'View Receipt',
      body: 'Goods dropped off.',
      timestamp: yesterday,
      isRead: true,
      actionLabel: 'View Receipt',
      actionBatchId: '8832',
    ),
    AppNotification(
      id: '5',
      type: NotificationType.batchCompleted,
      title: 'Batch Completed',
      body: 'Batch #8411 completed.',
      timestamp: yesterday.subtract(const Duration(hours: 2)),
      isRead: true,
    ),
  ];
}

// ── Test helpers ──────────────────────────────────────────────────────────────

Widget _buildTestApp(List<AppNotification> items) {
  final repo = _FakeNotificationsRepository(items);
  return ProviderScope(
    overrides: [
      notificationsRepositoryProvider.overrideWith((ref) => repo),
    ],
    child: MaterialApp.router(
      theme: ThemeData(extensions: const [AppColors.light]),
      routerConfig: GoRouter(
        initialLocation: '/notifications',
        routes: [
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('renders date-grouped sections and unread dots correctly',
      (tester) async {
    await tester.pumpWidget(_buildTestApp(_seedNotifications()));
    await tester.pump();

    // Section headers
    expect(find.text('TODAY (3)'), findsOneWidget);
    expect(find.text('YESTERDAY (2)'), findsOneWidget);

    // Unread dots visible for isRead: false items
    expect(find.byKey(const ValueKey('unread_dot_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('unread_dot_2')), findsOneWidget);

    // No unread dots for isRead: true items
    expect(find.byKey(const ValueKey('unread_dot_3')), findsNothing);
    expect(find.byKey(const ValueKey('unread_dot_4')), findsNothing);
    expect(find.byKey(const ValueKey('unread_dot_5')), findsNothing);
  });

  testWidgets('Mark all read removes all unread dots', (tester) async {
    await tester.pumpWidget(_buildTestApp(_seedNotifications()));
    await tester.pump();

    // Confirm dots are initially present
    expect(find.byKey(const ValueKey('unread_dot_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('unread_dot_2')), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pump();

    expect(find.byKey(const ValueKey('unread_dot_1')), findsNothing);
    expect(find.byKey(const ValueKey('unread_dot_2')), findsNothing);
  });
}
```

- [ ] **Step 2: Run tests — confirm they fail (NotificationsScreen doesn't exist yet)**

```bash
flutter test test/widget/notifications_screen_test.dart
```

Expected output: compile error — `Target of URI doesn't exist: 'package:saveameal/features/notifications/presentation/screens/notifications_screen.dart'`

- [ ] **Step 3: Commit the failing test**

```bash
git add test/widget/notifications_screen_test.dart
git commit -m "test(notifications): add widget tests (failing — screen not yet built)"
```

---

## Task 5: NotificationsScreen

**Files:**
- Create: `lib/features/notifications/presentation/screens/notifications_screen.dart`

- [ ] **Step 1: Create the screen**

```dart
// lib/features/notifications/presentation/screens/notifications_screen.dart
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
    final notifications = ref.watch(notificationsNotifierProvider);
    final notifier = ref.read(notificationsNotifierProvider.notifier);
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
          ? Center(
              child: Text('No notifications', style: textTheme.bodyMedium),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              children: _groupByDate(notifications).entries.map((entry) {
                return _DateGroup(
                  label: entry.key,
                  notifications: entry.value,
                  onTap: (n) => _onCardTap(context, ref, n),
                );
              }).toList(),
            ),
    );
  }

  Map<String, List<AppNotification>> _groupByDate(
    List<AppNotification> notifications,
  ) {
    final now = DateTime.now();
    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];

    for (final n in notifications) {
      if (_isSameDay(n.timestamp, now)) {
        today.add(n);
      } else if (_isSameDay(
        n.timestamp,
        now.subtract(const Duration(days: 1)),
      )) {
        yesterday.add(n);
      }
    }

    return {
      if (today.isNotEmpty) 'TODAY (${today.length})': today,
      if (yesterday.isNotEmpty) 'YESTERDAY (${yesterday.length})': yesterday,
    };
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onCardTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    ref.read(notificationsNotifierProvider.notifier).markRead(notification.id);
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

// ── Date group ────────────────────────────────────────────────────────────────

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.label,
    required this.notifications,
    required this.onTap,
  });

  final String label;
  final List<AppNotification> notifications;
  final void Function(AppNotification) onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
              Expanded(
                child: Divider(color: cs.outlineVariant, thickness: 1),
              ),
            ],
          ),
        ),
        ...notifications.map(
          (n) => _NotificationCard(notification: n, onTap: () => onTap(n)),
        ),
        const SizedBox(height: Spacing.sm),
      ],
    );
  }
}

// ── Notification card ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

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
                    style: textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    _relativeTime(notification.timestamp),
                    style: textTheme.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
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
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return 'yesterday at $h:$m';
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
            color: notification.isRead ? cs.surfaceContainerHighest : cs.primary,
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
                style: textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run the widget tests — confirm they pass**

```bash
flutter test test/widget/notifications_screen_test.dart
```

Expected:
```
00:XX +2: All tests passed!
```

- [ ] **Step 3: Run static analysis**

```bash
flutter analyze lib/features/notifications/
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/notifications/presentation/screens/notifications_screen.dart
git commit -m "feat(notifications): implement NotificationsScreen"
```

---

## Task 6: Router + dashboard wiring

**Files:**
- Modify: `lib/app/router.dart`
- Modify: `lib/features/donor/presentation/screens/donor_dashboard_screen.dart`
- Modify: `lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart`
- Modify: `lib/features/driver/presentation/screens/driver_map_screen.dart`
- Modify: `lib/features/driver/presentation/screens/claim_rescue_screen.dart`

- [ ] **Step 1: Add the import and `/notifications` route to `router.dart`**

Add this import with the other screen imports at the top of `lib/app/router.dart`:

```dart
import 'package:saveameal/features/notifications/presentation/screens/notifications_screen.dart';
```

Add this `GoRoute` to the `routes` list, after the `/beneficiary` route (before the closing `]`):

```dart
GoRoute(
  path: '/notifications',
  builder: (context, state) => const NotificationsScreen(),
),
```

- [ ] **Step 2: Wire the donor dashboard notification button**

In `lib/features/donor/presentation/screens/donor_dashboard_screen.dart`, find:

```dart
IconButton(
  icon: const Icon(Icons.notifications_outlined),
  onPressed: null,
),
```

Replace with:

```dart
IconButton(
  icon: const Icon(Icons.notifications_outlined),
  onPressed: () => context.push('/notifications'),
),
```

If `go_router` is not already imported at the top of this file, add:
```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 3: Wire the beneficiary dashboard notification button**

In `lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart`, find:

```dart
IconButton(
  icon: const Icon(Icons.notifications_outlined),
  onPressed: null,
),
```

Replace with:

```dart
IconButton(
  icon: const Icon(Icons.notifications_outlined),
  onPressed: () => context.push('/notifications'),
),
```

If `go_router` is not already imported, add:
```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 4: Wire the driver map screen notification button**

In `lib/features/driver/presentation/screens/driver_map_screen.dart`, the `actions` list is currently `const`. It must become non-const because the closure prevents it.

Find:
```dart
actions: const [
  IconButton(icon: Icon(Icons.notifications_outlined), onPressed: null),
  LogoutButton(),
],
```

Replace with:
```dart
actions: [
  IconButton(
    icon: const Icon(Icons.notifications_outlined),
    onPressed: () => context.push('/notifications'),
  ),
  const LogoutButton(),
],
```

- [ ] **Step 5: Wire the claim rescue screen notification button**

In `lib/features/driver/presentation/screens/claim_rescue_screen.dart`, find:

```dart
IconButton(
  icon: const Icon(Icons.notifications_outlined),
  onPressed: null,
),
```

Replace with:

```dart
IconButton(
  icon: const Icon(Icons.notifications_outlined),
  onPressed: () => context.push('/notifications'),
),
```

- [ ] **Step 6: Run analysis and format**

```bash
flutter analyze
dart format .
```

Expected: `No issues found!`

- [ ] **Step 7: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/app/router.dart \
        lib/features/donor/presentation/screens/donor_dashboard_screen.dart \
        lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart \
        lib/features/driver/presentation/screens/driver_map_screen.dart \
        lib/features/driver/presentation/screens/claim_rescue_screen.dart
git commit -m "feat(notifications): wire /notifications route and dashboard buttons"
```

---

## Self-review checklist

- [x] Entity covers all 6 `NotificationType` values used in the icon switch
- [x] Mock seeds 3 today + 2 yesterday → "TODAY (3)" / "YESTERDAY (2)" matches test assertions
- [x] `ValueKey('unread_dot_${id}')` used in both screen and test assertions — consistent
- [x] `AppColors.light` (const value, not factory) — matches `app_colors.dart`
- [x] Package name `saveameal` throughout — matches `router.dart` imports
- [x] `cs.surfaceContainerHighest` used instead of deprecated `cs.surfaceVariant`
- [x] `withValues(alpha: 0.06)` used instead of deprecated `withOpacity`
- [x] All 4 dashboard `onPressed: null` locations covered
- [x] `driver_map_screen.dart` `const` actions list changed to non-const
- [x] `/notifications` route added to router at root level (auth redirect already covers it)
- [x] Both widget tests have complete assertion code — no placeholders
