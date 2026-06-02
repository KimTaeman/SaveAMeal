# Driver Flow Figma Alignment — Design Spec
**Date:** 2026-06-02
**Feature:** Align all 5 driver screens to the Figma designs

---

## 1. Scope

Five driver screens updated to match Figma. No new routes, no new providers, no new data models.

| Screen | Change type |
|---|---|
| `ClaimRescueScreen` | Structural — AppBar, status header, layout, contact row, bottom nav |
| `PickupVerificationScreen` | Additive — donor info card, manual entry polish |
| `SafetyVerificationScreen` | Minor — dashed photo border |
| `VerifyDeliveryScreen` | Additive — batch identifier card |
| `DeliveryCompletedScreen` | Minor — concentric checkmark, icons on impact tiles |

**Out of scope:** Navigation turn-by-turn directions, real ETA from routing API, driver distance calculation, Driver Map category chips.

---

## 2. ClaimRescueScreen

File: `apps/mobile/lib/features/driver/presentation/screens/claim_rescue_screen.dart`

### 2.1 Layout

```
AppBar: ← back   CURRENT DELIVERY / Status: <phase>   🔔
─────────────────────────────────────────────────────
GoogleMap (~40% height)
  └─ ETA chip (bottom-right): "~14 min" hardcoded
─────────────────────────────────────────────────────
DESTINATION section          [📞 phone icon]
  <destinationName>
  📍 <location label>: <address>
  ⚠  <contact label>: <contact>
─────────────────────────────────────────────────────
🗂 <N>x <description>    View Details →
─────────────────────────────────────────────────────
FilledButton: "Arrived at Pick-up" | "Arrived at Drop-off"
─────────────────────────────────────────────────────
NavigationBar: Home | Impact | Account
```

### 2.2 Data mapping

| UI element | enRoutePickup | enRouteBeneficiary |
|---|---|---|
| Status text | "En Route to Pick-up" | "En Route to Beneficiary" |
| Destination name | `batch.donorName` | `batch.beneficiaryName` |
| Location label | "Pick-up Location" | "Drop-off Location" |
| Address | `batch.pickupAddress` | `batch.beneficiaryAddress` |
| Contact label | "Pick-up Contact" | "Drop-off Contact" |
| Contact value | `batch.donorContact ?? 'Ask for staff'` | `'Ask for shelter staff'` |
| Batch description | `'${batch.totalPortions}x ${batch.items.first.name}'` | same |
| CTA label | "Arrived at Pick-up" | "Arrived at Drop-off" |

### 2.3 ETA chip

Hardcoded "~14 min" in a `Container` overlay on the map (bottom-right corner). Positioned using `Align(alignment: Alignment.bottomRight)` inside a `Stack` wrapping the `GoogleMap`.

### 2.4 "View Details" tap

`context.push('/driver/job/${batch.id}', extra: batch)` — re-uses existing `JobDetailScreen`.

### 2.5 Bottom NavigationBar

```dart
NavigationBar(
  selectedIndex: 0,
  onDestinationSelected: (_) {}, // single destination for now
  destinations: [
    NavigationDestination(icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart), label: 'Impact'),
    NavigationDestination(icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person), label: 'Account'),
  ],
)
```

### 2.6 AppBar

```dart
AppBar(
  leading: const BackButton(),
  title: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('CURRENT DELIVERY', style: textTheme.labelSmall),
      Text('Status: $statusText', style: textTheme.titleSmall),
    ],
  ),
  actions: [IconButton(icon: Icon(Icons.notifications_outlined), onPressed: null)],
)
```

---

## 3. PickupVerificationScreen

File: `apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart`

### 3.1 Donor info card

A white rounded card overlaying the bottom portion of the camera view, sitting above the "Problems scanning?" row. Uses `batch` from `ref.watch(driverProvider).activeBatch`.

```
┌──────────────────────────────────┐
│ 🏪 <donorName>                   │
│                                  │
│ EXPECTED PICKUP                  │
│ <totalPortions> portions  <desc> │
└──────────────────────────────────┘
```

- `desc` = `batch.items.isNotEmpty ? batch.items.first.name : batch.foodCategory`
- Card sits inside the `Stack` at `Align(alignment: Alignment.bottomCenter)`, above the existing manual entry row

### 3.2 Manual entry polish

- Add `Icons.qr_code_scanner` icon before "Problems scanning? Enter code manually" text
- Inside `_showManualEntry` dialog: add `autofocus: true` to the `TextField`
- Disable Confirm button when `controller.text.trim().isEmpty` using `StatefulBuilder`

---

## 4. SafetyVerificationScreen

File: `apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart`

### 4.1 Dashed photo border

Replace `Border.all(color: cs.primary)` on the photo upload container with a `CustomPaint` dashed border:

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
    final radius = Radius.circular(12);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, radius));
    // Draw dashed path
    var distance = 0.0;
    bool draw = true;
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
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
```

Use `CustomPaint(painter: _DashedBorderPainter(color: cs.primary), child: ...)` wrapping the photo upload container. Remove the `BoxDecoration.border`.

---

## 5. VerifyDeliveryScreen

File: `apps/mobile/lib/features/driver/presentation/screens/verify_delivery_screen.dart`

### 5.1 Batch identifier card

Add at the very top of the `ListView`, before the "Handover Verification" section:

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(Spacing.md),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BATCH IDENTIFIER', style: textTheme.labelSmall),
            Text('Batch #${_formatBatchId(batch.id)}',
                style: textTheme.titleMedium),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('VOLUME', style: textTheme.labelSmall),
            Text('${batch.totalPortions} Portions',
                style: textTheme.titleMedium?.copyWith(color: cs.primary)),
          ],
        ),
      ],
    ),
  ),
)
```

`_formatBatchId` helper: `batch.id.split('_').last` — e.g. `batch_001` → `001`.

### 5.2 Batch data source

The screen currently calls `activeBatchForDriverProvider(uid)` inside `_confirm()` only. Add these two reads at the top of `build()` to expose `batch` for the card:

```dart
final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
final batch = ref.watch(activeBatchForDriverProvider(uid)).asData?.value;
```

Import `auth_provider.dart` and `driver_provider.dart` if not already present. Hide the card entirely when `batch == null`.

---

## 6. DeliveryCompletedScreen

File: `apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart`

### 6.1 Concentric checkmark

Replace the single `Container` circle with a `Stack` of three concentric circles:

```dart
Stack(
  alignment: Alignment.center,
  children: [
    Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer.withOpacity( 0.3),
      ),
    ),
    Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primaryContainer.withOpacity( 0.6),
      ),
    ),
    Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primary,
      ),
      child: Icon(Icons.check, color: cs.onPrimary, size: 32),
    ),
  ],
),
```

### 6.2 Impact tile icons

Add an icon above the value in each `_ImpactTile`. Update `_ImpactTile` to accept an optional `IconData`:

```dart
class _ImpactTile extends StatelessWidget {
  const _ImpactTile({required this.value, required this.label, this.icon});
  final String value;
  final String label;
  final IconData? icon;
  // ...
}
```

Usage:
```dart
_ImpactTile(icon: Icons.cloud_outlined, value: '...', label: 'CO2 SAVED')
_ImpactTile(icon: Icons.restaurant, value: '...', label: 'MEALS PROVIDED')
```

---

## 7. Files Changed

| File | Change |
|---|---|
| `claim_rescue_screen.dart` | Structural rewrite: AppBar, status header, layout resize, contact row, ETA chip, View Details, fix CTA label, add NavigationBar |
| `pickup_verification_screen.dart` | Add donor info card; polish manual entry dialog |
| `safety_verification_screen.dart` | Add `_DashedBorderPainter`; replace solid border |
| `verify_delivery_screen.dart` | Add batch identifier card at top |
| `delivery_completed_screen.dart` | Concentric checkmark; `_ImpactTile` icon param |
