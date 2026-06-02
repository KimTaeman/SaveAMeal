# Driver Flow Figma Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align all five driver screens to the Figma designs — ClaimRescueScreen, PickupVerificationScreen, SafetyVerificationScreen, VerifyDeliveryScreen, and DeliveryCompletedScreen.

**Architecture:** Pure UI changes — no new routes, providers, or data models. Each task modifies exactly one screen file and its corresponding test. All data is already available through existing `driverProvider`, `activeBatchForDriverProvider`, and `authStateProvider`.

**Tech Stack:** Flutter (`google_maps_flutter`, `flutter_riverpod`, `go_router`), existing `BatchSummary` domain entity, `Spacing` constants from `shared/theme/spacing.dart`.

---

## File Map

| File | Change |
|---|---|
| `apps/mobile/lib/features/driver/presentation/screens/claim_rescue_screen.dart` | Rewrite: AppBar, status header, ETA chip, contact row, batch row, fix CTA label, NavigationBar |
| `apps/mobile/test/widget/driver/claim_rescue_screen_test.dart` | Update "Arrived at Beneficiary" → "Arrived at Drop-off"; add status text assertions |
| `apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart` | Add `_DonorInfoCard` widget; polish `_showManualEntry` dialog |
| `apps/mobile/test/widget/driver/pickup_verification_screen_test.dart` | Add test: donor card renders when active batch present |
| `apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart` | Add `_DashedBorderPainter`; replace solid border on photo upload |
| `apps/mobile/lib/features/driver/presentation/screens/verify_delivery_screen.dart` | Add batch identifier card at top; expose batch in `build()` |
| `apps/mobile/test/widget/driver/verify_delivery_screen_test.dart` | Add test: batch card shows when batch is present |
| `apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart` | Concentric checkmark; add `icon` param to `_ImpactTile` |

---

## Task 1: ClaimRescueScreen — full layout update

**Files:**
- Modify: `apps/mobile/lib/features/driver/presentation/screens/claim_rescue_screen.dart`
- Modify: `apps/mobile/test/widget/driver/claim_rescue_screen_test.dart`

- [ ] **Step 1: Update the failing test first**

Open `apps/mobile/test/widget/driver/claim_rescue_screen_test.dart`.

In `main()`, the second test currently expects `find.text('Arrived at Beneficiary')`. The CTA is changing to "Arrived at Drop-off". Update the second test and add a status-text assertion to both tests:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/claim_rescue_screen.dart';

const _fakeBatch = BatchSummary(
  id: 'b1',
  donorName: 'Central Bakery',
  pickupAddress: '123 Baker St',
  beneficiaryAddress: '1200 Greenway Blvd',
  beneficiaryName: 'Haven Shelter',
  totalPortions: 38,
  lat: 13.7,
  lng: 100.5,
  foodCategory: 'local_pizza',
);

class _FakeNotifier extends DriverNotifier {
  _FakeNotifier(this._initial);
  final DriverState _initial;
  @override
  DriverState build() => _initial;
}

void main() {
  testWidgets('en_route_pickup shows donor address and Arrived at Pick-up', (
    tester,
  ) async {
    final notifier = _FakeNotifier(
      const DriverState(
        step: DriverStep.claimed,
        rescuePhase: ClaimRescuePhase.enRoutePickup,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverProvider.overrideWith(() => notifier),
          authStateProvider.overrideWith((_) => const Stream.empty()),
          activeBatchForDriverProvider(
            '',
          ).overrideWith((_) => Stream.value(_fakeBatch)),
        ],
        child: const MaterialApp(home: ClaimRescueScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('123 Baker St'), findsOneWidget);
    expect(find.text('Arrived at Pick-up'), findsOneWidget);
    expect(find.text('Arrived at Drop-off'), findsNothing);
    expect(find.textContaining('En Route to Pick-up'), findsOneWidget);
  });

  testWidgets('en_route_beneficiary shows shelter address and Arrived at Drop-off', (
    tester,
  ) async {
    final notifier = _FakeNotifier(
      const DriverState(
        step: DriverStep.pickedUp,
        rescuePhase: ClaimRescuePhase.enRouteBeneficiary,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driverProvider.overrideWith(() => notifier),
          authStateProvider.overrideWith((_) => const Stream.empty()),
          activeBatchForDriverProvider(
            '',
          ).overrideWith((_) => Stream.value(_fakeBatch)),
        ],
        child: const MaterialApp(home: ClaimRescueScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('1200 Greenway Blvd'), findsOneWidget);
    expect(find.text('Arrived at Drop-off'), findsOneWidget);
    expect(find.text('Arrived at Pick-up'), findsNothing);
    expect(find.textContaining('En Route to Beneficiary'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd apps/mobile
flutter test test/widget/driver/claim_rescue_screen_test.dart
```

Expected: FAIL — "Arrived at Beneficiary" no longer in widget tree; "En Route to Pick-up" not yet rendered.

- [ ] **Step 3: Replace `claim_rescue_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class ClaimRescueScreen extends ConsumerWidget {
  const ClaimRescueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverState = ref.watch(driverProvider);
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final batch = ref.watch(activeBatchForDriverProvider(uid)).asData?.value;
    final isPickup = driverState.rescuePhase == ClaimRescuePhase.enRoutePickup;

    final statusText =
        isPickup ? 'En Route to Pick-up' : 'En Route to Beneficiary';
    final destinationName =
        isPickup ? batch?.donorName ?? '—' : batch?.beneficiaryName ?? '—';
    final locationLabel = isPickup ? 'Pick-up Location' : 'Drop-off Location';
    final address = isPickup
        ? batch?.pickupAddress ?? '—'
        : batch?.beneficiaryAddress ?? '—';
    final contactLabel =
        isPickup ? 'Pick-up Contact' : 'Drop-off Contact';
    final contact = isPickup
        ? (batch?.donorContact ?? 'Ask for staff')
        : 'Ask for shelter staff';
    final cta = isPickup ? 'Arrived at Pick-up' : 'Arrived at Drop-off';
    final description = batch != null && batch.items.isNotEmpty
        ? '${batch.totalPortions}x ${batch.items.first.name}'
        : '${batch?.totalPortions ?? 0}x portions';

    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CURRENT DELIVERY',
              style: textTheme.labelSmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            Text(
              'Status: $statusText',
              style: textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Map with ETA chip overlay
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.38,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      batch?.lat ?? 13.7563,
                      batch?.lng ?? 100.5018,
                    ),
                    zoom: 14,
                  ),
                  markers: batch != null
                      ? {
                          Marker(
                            markerId: const MarkerId('dest'),
                            position: LatLng(batch.lat, batch.lng),
                          ),
                        }
                      : {},
                ),
                Positioned(
                  right: Spacing.sm,
                  bottom: Spacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 14, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          '~14 min',
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Destination + actions
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DESTINATION',
                        style: textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      Icon(Icons.phone_outlined,
                          size: 18, color: cs.primary),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(destinationName, style: textTheme.titleMedium),
                  const SizedBox(height: Spacing.sm),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: locationLabel,
                    value: address,
                  ),
                  const SizedBox(height: Spacing.xs),
                  _InfoRow(
                    icon: Icons.warning_amber_outlined,
                    label: contactLabel,
                    value: contact,
                  ),
                  const Spacer(),
                  if (batch != null)
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: Spacing.xs),
                        Text(description, style: textTheme.bodySmall),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push(
                            '/driver/job/${batch.id}',
                            extra: batch,
                          ),
                          child: Text(
                            'View Details',
                            style: textTheme.labelSmall
                                ?.copyWith(color: cs.primary),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: Spacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => _onArrived(context, isPickup),
                      label: Text(cta),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Impact',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  void _onArrived(BuildContext context, bool isPickup) {
    if (isPickup) {
      context.push('/driver/pickup-verify');
    } else {
      context.push('/driver/verify-delivery');
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: Spacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(value, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
cd apps/mobile
flutter test test/widget/driver/claim_rescue_screen_test.dart
```

Expected: `All 2 tests passed.`

- [ ] **Step 5: Run full suite**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/driver/presentation/screens/claim_rescue_screen.dart \
        apps/mobile/test/widget/driver/claim_rescue_screen_test.dart
git commit -m "feat: align ClaimRescueScreen to Figma — status header, contact row, ETA chip, fix CTA label"
```

---

## Task 2: PickupVerificationScreen — donor info card + manual entry polish

**Files:**
- Modify: `apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart`
- Modify: `apps/mobile/test/widget/driver/pickup_verification_screen_test.dart`

- [ ] **Step 1: Add a failing test for the donor card**

Open `apps/mobile/test/widget/driver/pickup_verification_screen_test.dart`. Add a new test at the end of `main()`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/pickup_verification_screen.dart';

const _fakeBatch = BatchSummary(
  id: 'b1',
  donorName: 'Central Bakery',
  pickupAddress: '123 Baker St',
  beneficiaryAddress: '1200 Greenway Blvd',
  beneficiaryName: 'Haven Shelter',
  totalPortions: 38,
  lat: 13.7,
  lng: 100.5,
  foodCategory: 'local_pizza',
);

class _FakeNotifier extends DriverNotifier {
  @override
  DriverState build() => DriverState(
        step: DriverStep.claimed,
        rescuePhase: ClaimRescuePhase.enRoutePickup,
        activeBatch: _fakeBatch,
      );
}

Widget _wrapWithBatch() => ProviderScope(
      overrides: [driverProvider.overrideWith(() => _FakeNotifier())],
      child: const MaterialApp(home: PickupVerificationScreen()),
    );

Widget _wrap() =>
    const ProviderScope(child: MaterialApp(home: PickupVerificationScreen()));

void main() {
  testWidgets('shows Verify Pickup title and scan instructions', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('Verify Pickup'), findsOneWidget);
    expect(find.text("Scan the QR code on the donor's device"), findsOneWidget);
    expect(find.text('Problems scanning? Enter code manually'), findsOneWidget);
  });

  testWidgets('tapping manual entry shows dialog', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Problems scanning? Enter code manually'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Enter Batch ID'), findsOneWidget);
  });

  testWidgets('donor info card shows donor name and portions when batch active',
      (tester) async {
    await tester.pumpWidget(_wrapWithBatch());
    await tester.pump();
    expect(find.text('Central Bakery'), findsOneWidget);
    expect(find.text('38 portions'), findsOneWidget);
  });

  testWidgets('manual entry Confirm is disabled when text is empty', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.text('Problems scanning? Enter code manually'));
    await tester.pumpAndSettle();
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm'),
    );
    expect(confirm.onPressed, isNull);
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd apps/mobile
flutter test test/widget/driver/pickup_verification_screen_test.dart
```

Expected: FAIL — "Central Bakery" not found; Confirm button not yet disabled when empty.

- [ ] **Step 3: Replace `pickup_verification_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/shared/theme/spacing.dart';

class PickupVerificationScreen extends ConsumerStatefulWidget {
  const PickupVerificationScreen({super.key});

  @override
  ConsumerState<PickupVerificationScreen> createState() =>
      _PickupVerificationScreenState();
}

class _PickupVerificationScreenState
    extends ConsumerState<PickupVerificationScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
  );
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    _validateAndNavigate(raw);
  }

  Future<void> _validateAndNavigate(String scannedBatchId) async {
    final activeBatch = ref.read(driverProvider).activeBatch;
    if (activeBatch == null || activeBatch.id != scannedBatchId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong QR code — try again.')),
        );
      }
      return;
    }
    _scanned = true;
    if (mounted) context.push('/driver/safety');
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Enter Batch ID'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g. batch_001'),
            onChanged: (_) => setDialogState(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () {
                      Navigator.of(ctx).pop();
                      _validateAndNavigate(controller.text.trim());
                    },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batch = ref.watch(driverProvider).activeBatch;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Pickup')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Text(
                "Scan the QR code on the donor's device",
                style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Center(
            child: CustomPaint(
              size: const Size(220, 220),
              painter: _ReticlePainter(color: cs.primary),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (batch != null) ...[
                      _DonorInfoCard(batch: batch),
                      const SizedBox(height: Spacing.sm),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextButton.icon(
                        onPressed: _showManualEntry,
                        icon: const Icon(Icons.qr_code_scanner, size: 16),
                        label: const Text(
                          'Problems scanning? Enter code manually',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorInfoCard extends StatelessWidget {
  const _DonorInfoCard({required this.batch});
  final BatchSummary batch;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final desc = batch.items.isNotEmpty
        ? batch.items.first.name
        : batch.foodCategory;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.store_outlined, size: 18, color: cs.primary),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.donorName, style: textTheme.titleSmall),
                const SizedBox(height: Spacing.xs),
                Text(
                  'EXPECTED PICKUP',
                  style: textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                Row(
                  children: [
                    Text(
                      '${batch.totalPortions} portions',
                      style: textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Text(
                        desc,
                        style:
                            textTheme.bodySmall?.copyWith(color: cs.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 40.0;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(0, len), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(len, 0), paint);
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
  }

  @override
  bool shouldRepaint(_ReticlePainter old) => old.color != color;
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd apps/mobile
flutter test test/widget/driver/pickup_verification_screen_test.dart
```

Expected: `All 4 tests passed.`

- [ ] **Step 5: Run full suite**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart \
        apps/mobile/test/widget/driver/pickup_verification_screen_test.dart
git commit -m "feat: add donor info card to PickupVerificationScreen; polish manual entry dialog"
```

---

## Task 3: SafetyVerificationScreen — dashed photo border

**Files:**
- Modify: `apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart`

- [ ] **Step 1: Add `_DashedBorderPainter` and replace the solid border**

Open `apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart`.

Add `_DashedBorderPainter` at the bottom of the file (after the existing class), and update the photo upload container to use it.

**Replace** the `GestureDetector` photo upload widget (starting at the `GestureDetector(onTap: _pickPhoto, ...)`) with:

```dart
          GestureDetector(
            onTap: _pickPhoto,
            child: CustomPaint(
              painter: _DashedBorderPainter(color: cs.primary),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _pickedBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_pickedBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: cs.primary, size: 32),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            'Upload Pickup Photo',
                            style: textTheme.labelMedium
                                ?.copyWith(color: cs.primary),
                          ),
                          Text(
                            'Tap to select or take photo',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
              ),
            ),
          ),
```

Add `_DashedBorderPainter` class at the end of the file:

```dart
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 8.0;
    const dashSpace = 5.0;
    const radius = Radius.circular(12);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, radius));
    var distance = 0.0;
    var draw = true;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final len = draw ? dashWidth : dashSpace;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += len;
        draw = !draw;
      }
      distance = 0.0;
      draw = true;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
```

- [ ] **Step 2: Analyze**

```bash
cd apps/mobile && flutter analyze lib/features/driver/presentation/screens/safety_verification_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Run tests**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart
git commit -m "feat: dashed photo upload border on SafetyVerificationScreen"
```

---

## Task 4: VerifyDeliveryScreen — batch identifier card

**Files:**
- Modify: `apps/mobile/lib/features/driver/presentation/screens/verify_delivery_screen.dart`
- Modify: `apps/mobile/test/widget/driver/verify_delivery_screen_test.dart`

- [ ] **Step 1: Add a failing test for the batch card**

Open `apps/mobile/test/widget/driver/verify_delivery_screen_test.dart`. Add one test at the end of `main()`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/driver/domain/repositories/driver_repository.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_notifier.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_provider.dart';
import 'package:saveameal/features/driver/presentation/providers/driver_state.dart';
import 'package:saveameal/features/driver/presentation/screens/verify_delivery_screen.dart';

const _fakeBatch = BatchSummary(
  id: 'batch_001',
  donorName: 'Central Bakery',
  pickupAddress: '123 Baker St',
  beneficiaryAddress: '1200 Greenway Blvd',
  beneficiaryName: 'Haven Shelter',
  totalPortions: 38,
  lat: 13.7,
  lng: 100.5,
  foodCategory: 'local_pizza',
);

class _FakeNotifier extends DriverNotifier {
  @override
  DriverState build() => const DriverState(step: DriverStep.pickedUp);
}

Widget _wrapWithBatch() => ProviderScope(
      overrides: [
        driverProvider.overrideWith(() => _FakeNotifier()),
        authStateProvider.overrideWith((_) => const Stream.empty()),
        activeBatchForDriverProvider(
          '',
        ).overrideWith((_) => Stream.value(_fakeBatch)),
      ],
      child: const MaterialApp(home: VerifyDeliveryScreen()),
    );

Widget _wrap() =>
    const ProviderScope(child: MaterialApp(home: VerifyDeliveryScreen()));

void main() {
  testWidgets('CTA disabled with nothing checked', (tester) async {
    await tester.pumpWidget(_wrap());
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm Delivery Completion'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows both handover verification items', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(
      find.text('Food batch handed over securely to shelter staff'),
      findsOneWidget,
    );
    expect(
      find.text('Shelter staff confirmed item quantities match'),
      findsOneWidget,
    );
  });

  testWidgets('CTA enabled after both checkboxes selected', (tester) async {
    await tester.pumpWidget(_wrap());
    final checks = find.byType(CheckboxListTile);
    await tester.tap(checks.at(0));
    await tester.pump();
    await tester.tap(checks.at(1));
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm Delivery Completion'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('batch identifier card shows id and portions when batch active',
      (tester) async {
    await tester.pumpWidget(_wrapWithBatch());
    await tester.pump();
    expect(find.text('Batch #001'), findsOneWidget);
    expect(find.text('38 Portions'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
cd apps/mobile
flutter test test/widget/driver/verify_delivery_screen_test.dart
```

Expected: FAIL — "Batch #001" and "38 Portions" not found.

- [ ] **Step 3: Update `verify_delivery_screen.dart`**

`auth_provider.dart` and `driver_provider.dart` are already imported — no new imports needed.

Add these two lines at the start of `_VerifyDeliveryScreenState.build()`, before the `return Scaffold(...)` line:

Actually, `VerifyDeliveryScreen` is a `ConsumerStatefulWidget`. Add in `_VerifyDeliveryScreenState.build()`:

```dart
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final batch = ref.watch(activeBatchForDriverProvider(uid)).asData?.value;
```

Then add the batch identifier card as the **first item** in the `ListView.children` list, before the existing `Row(children: [Icon(Icons.verified...)`:

```dart
          if (batch != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BATCH IDENTIFIER',
                          style: textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        Text(
                          'Batch #${batch.id.split('_').last}',
                          style: textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'VOLUME',
                          style: textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        Text(
                          '${batch.totalPortions} Portions',
                          style: textTheme.titleMedium
                              ?.copyWith(color: cs.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
```

Add `final cs = Theme.of(context).colorScheme;` and `final textTheme = Theme.of(context).textTheme;` if not already present in `build()`. The current `build()` already has `cs` and `textTheme` declared — insert the new code before the `Row(children: [Icon(Icons.verified...)` line.

Full `build()` method after changes:

```dart
  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
    final batch = ref.watch(activeBatchForDriverProvider(uid)).asData?.value;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Delivery')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          if (batch != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BATCH IDENTIFIER',
                          style: textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        Text(
                          'Batch #${batch.id.split('_').last}',
                          style: textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'VOLUME',
                          style: textTheme.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        Text(
                          '${batch.totalPortions} Portions',
                          style: textTheme.titleMedium
                              ?.copyWith(color: cs.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
          ],
          Row(
            children: [
              Icon(Icons.verified, color: cs.primary),
              const SizedBox(width: Spacing.sm),
              Text('Handover Verification', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          ...List.generate(
            _handoverItems.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: CheckboxListTile(
                title: Text(_handoverItems[i]),
                value: _checked[i],
                onChanged: (v) => setState(() => _checked[i] = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text('NOTES OR FEEDBACK (OPTIONAL)', style: textTheme.labelSmall),
          const SizedBox(height: Spacing.xs),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'E.g., Storage location, specific staff member name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: FilledButton(
            onPressed: _canConfirm ? _confirm : null,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm Delivery Completion'),
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
cd apps/mobile
flutter test test/widget/driver/verify_delivery_screen_test.dart
```

Expected: `All 4 tests passed.`

- [ ] **Step 5: Run full suite**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add apps/mobile/lib/features/driver/presentation/screens/verify_delivery_screen.dart \
        apps/mobile/test/widget/driver/verify_delivery_screen_test.dart
git commit -m "feat: add batch identifier card to VerifyDeliveryScreen"
```

---

## Task 5: DeliveryCompletedScreen — concentric checkmark + impact tile icons

**Files:**
- Modify: `apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart`

- [ ] **Step 1: Update `_ImpactTile` to accept an optional icon**

Open `apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart`.

Replace the `_ImpactTile` class:

```dart
class _ImpactTile extends StatelessWidget {
  const _ImpactTile({required this.value, required this.label, this.icon});
  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, color: cs.onSurfaceVariant, size: 22),
            const SizedBox(height: Spacing.xs),
          ],
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style:
                textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Update the two `_ImpactTile` usages to pass icons**

In the `Row` that contains the two tiles, replace:

```dart
                          Expanded(
                            child: _ImpactTile(
                              value: batch != null
                                  ? '${(batch.totalPortions * 0.4).toStringAsFixed(0)} kg'
                                  : '—',
                              label: 'CO2 SAVED',
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: _ImpactTile(
                              value: '${batch?.totalPortions ?? 0}',
                              label: 'MEALS PROVIDED',
                            ),
                          ),
```

with:

```dart
                          Expanded(
                            child: _ImpactTile(
                              icon: Icons.cloud_outlined,
                              value: batch != null
                                  ? '${(batch.totalPortions * 0.4).toStringAsFixed(0)} kg'
                                  : '—',
                              label: 'CO2 SAVED',
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: _ImpactTile(
                              icon: Icons.restaurant,
                              value: '${batch?.totalPortions ?? 0}',
                              label: 'MEALS PROVIDED',
                            ),
                          ),
```

- [ ] **Step 3: Replace the single checkmark circle with a concentric stack**

Find and replace the current checkmark widget:

```dart
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: cs.primary, size: 48),
              ),
```

with:

```dart
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer.withOpacity(0.3),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer.withOpacity(0.6),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                    ),
                    child: Icon(Icons.check, color: cs.onPrimary, size: 32),
                  ),
                ],
              ),
```

- [ ] **Step 4: Run tests**

```bash
cd apps/mobile && flutter test
```

Expected: all tests pass (existing delivery_completed tests check text content, not widget types).

- [ ] **Step 5: Commit**

```bash
git add apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart
git commit -m "feat: concentric checkmark and icons on DeliveryCompletedScreen"
```

---

## Final Verification

```bash
cd apps/mobile
flutter analyze
flutter test
```

Expected: no issues, all tests pass.

**Manual demo check — walk the driver flow:**
1. Accept a job → `ClaimRescueScreen` shows "Status: En Route to Pick-up", contact row, ETA chip, "Arrived at Pick-up" button
2. Tap Arrived → `PickupVerificationScreen` shows camera + donor info card (donor name, 38 portions)
3. Enter code manually → dialog auto-focuses, Confirm disabled when empty
4. After scan → `SafetyVerificationScreen` shows dashed border on photo upload
5. After pickup → `ClaimRescueScreen` shows "En Route to Beneficiary", "Arrived at Drop-off"
6. Arrive → `VerifyDeliveryScreen` shows "Batch #001 / 38 Portions" card at top
7. Complete → `DeliveryCompletedScreen` shows concentric checkmark, cloud and fork icons
