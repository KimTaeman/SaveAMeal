# Donor Address → Google Maps Link Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add lat/lng storage and two address-field icon buttons (📍 current location, 🗺 open in Maps) to both `DonorOrgSetupScreen` and `OrganizationProfileScreen`.

**Architecture:** Extend the existing `UserModel` / `DonorProfile` / `UserProfileUpdate` stack with nullable `latitude` / `longitude` doubles. Each org-profile screen gains a `_fetchLocation()` method (geolocator) and `_openInMaps()` method (url_launcher) exposed as icon buttons in the `Street Address` field's `suffixIcon`. Coordinates are persisted via the existing `updateUserUsecaseProvider` with no new use cases or providers.

**Tech Stack:** `geolocator ^13.0.0` (already in pubspec), `url_launcher ^6.3.1` (new), Freezed codegen, Riverpod, GoRouter.

---

## File Map

| Action | File |
|---|---|
| Modify | `apps/mobile/pubspec.yaml` |
| Modify | `apps/mobile/lib/core/models/user_model.dart` |
| Modify | `apps/mobile/lib/features/donor/domain/entities/donor_profile.dart` |
| Modify | `apps/mobile/lib/features/donor/domain/entities/user_profile_update.dart` |
| Modify | `apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart` |
| Modify | `apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart` |
| Modify | `apps/mobile/lib/features/donor/presentation/screens/donor_org_setup_screen.dart` |
| Modify | `apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart` |
| Modify | `apps/mobile/test/widget/features/donor/donor_org_setup_screen_test.dart` |
| Modify | `apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart` |

---

## Task 1: Data layer — add lat/lng fields

**Files:**
- Modify: `apps/mobile/lib/core/models/user_model.dart`
- Modify: `apps/mobile/lib/features/donor/domain/entities/donor_profile.dart`
- Modify: `apps/mobile/lib/features/donor/domain/entities/user_profile_update.dart`
- Modify: `apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart`
- Modify: `apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart`

- [ ] **Step 1.1 — Add fields to `UserModel`**

Replace the existing `UserModel` factory with:

```dart
// apps/mobile/lib/core/models/user_model.dart
@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    String? phone,
    String? orgName,
    String? location,
    String? photoUrl,
    String? managerName,
    String? streetAddress,
    String? bannerUrl,
    BeneficiaryStatus? status,
    @Default(0) int points,
    @Default([]) List<Map<String, String>> operatingHours,
    @Default([]) List<String> surplusTypes,
    String? fcmToken,
    double? latitude,
    double? longitude,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

- [ ] **Step 1.2 — Run Freezed codegen**

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected output: `[INFO] Succeeded after...` with no errors. The `user_model.freezed.dart` and `user_model.g.dart` files are regenerated.

- [ ] **Step 1.3 — Add fields to `DonorProfile`**

```dart
// apps/mobile/lib/features/donor/domain/entities/donor_profile.dart
// Pure Dart entity — zero Flutter or backend imports.
class DonorProfile {
  const DonorProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.location,
    this.photoUrl,
    this.orgName,
    this.managerName,
    this.streetAddress,
    this.bannerUrl,
    this.operatingHours = const [],
    this.surplusTypes = const [],
    this.latitude,
    this.longitude,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? location;
  final String? photoUrl;
  final String? orgName;
  final String? managerName;
  final String? streetAddress;
  final String? bannerUrl;
  final List<Map<String, String>> operatingHours;
  final List<String> surplusTypes;
  final double? latitude;
  final double? longitude;
}
```

- [ ] **Step 1.4 — Add fields to `UserProfileUpdate`**

```dart
// apps/mobile/lib/features/donor/domain/entities/user_profile_update.dart
// Pure Dart entity — zero Flutter or backend imports.
class UserProfileUpdate {
  const UserProfileUpdate({
    this.name,
    this.phone,
    this.location,
    this.photoUrl,
    this.orgName,
    this.managerName,
    this.streetAddress,
    this.bannerUrl,
    this.operatingHours,
    this.surplusTypes,
    this.latitude,
    this.longitude,
  });

  final String? name;
  final String? phone;
  final String? location;
  final String? photoUrl;
  final String? orgName;
  final String? managerName;
  final String? streetAddress;
  final String? bannerUrl;
  final List<Map<String, String>>? operatingHours;
  final List<String>? surplusTypes;
  final double? latitude;
  final double? longitude;
}
```

- [ ] **Step 1.5 — Update `_toFirestoreMap` in datasource**

```dart
// apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart
Map<String, dynamic> _toFirestoreMap(UserProfileUpdate u) => {
  if (u.name != null) 'name': u.name,
  if (u.phone != null) 'phone': u.phone,
  if (u.location != null) 'location': u.location,
  if (u.photoUrl != null) 'photoUrl': u.photoUrl,
  if (u.orgName != null) 'orgName': u.orgName,
  if (u.managerName != null) 'managerName': u.managerName,
  if (u.streetAddress != null) 'streetAddress': u.streetAddress,
  if (u.bannerUrl != null) 'bannerUrl': u.bannerUrl,
  if (u.operatingHours != null) 'operatingHours': u.operatingHours,
  if (u.surplusTypes != null) 'surplusTypes': u.surplusTypes,
  if (u.latitude != null) 'latitude': u.latitude,
  if (u.longitude != null) 'longitude': u.longitude,
};
```

- [ ] **Step 1.6 — Update `_toDomain` in repository**

```dart
// apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart
DonorProfile? _toDomain(UserModel? model) {
  if (model == null) return null;
  return DonorProfile(
    uid: model.uid,
    name: model.name,
    email: model.email,
    role: model.role.name,
    phone: model.phone,
    location: model.location,
    photoUrl: model.photoUrl,
    orgName: model.orgName,
    managerName: model.managerName,
    streetAddress: model.streetAddress,
    bannerUrl: model.bannerUrl,
    operatingHours: model.operatingHours,
    surplusTypes: model.surplusTypes,
    latitude: model.latitude,
    longitude: model.longitude,
  );
}
```

- [ ] **Step 1.7 — Verify no analysis errors**

```bash
cd apps/mobile
flutter analyze lib/core/models/user_model.dart lib/features/donor/
```

Expected: `No issues found!`

- [ ] **Step 1.8 — Commit**

```bash
cd apps/mobile
dart format .
cd ../..
git add apps/mobile/lib/core/models/ apps/mobile/lib/features/donor/domain/entities/ apps/mobile/lib/features/donor/data/
git commit -m "feat(donor): add latitude/longitude fields to UserModel, DonorProfile, UserProfileUpdate and wire through data layer"
```

---

## Task 2: Add url_launcher dependency

**Files:**
- Modify: `apps/mobile/pubspec.yaml`

- [ ] **Step 2.1 — Add url_launcher to pubspec.yaml**

In `apps/mobile/pubspec.yaml`, add under the `# ── Maps & Location` section:

```yaml
  # ── Maps & Location ───────────────────────────────────────────────────────────
  google_maps_flutter: ^2.9.0
  geolocator: ^13.0.0
  url_launcher: ^6.3.1
```

- [ ] **Step 2.2 — Install**

```bash
cd apps/mobile
flutter pub get
```

Expected: `Got dependencies!` with no errors.

- [ ] **Step 2.3 — Commit**

```bash
cd ../..
git add apps/mobile/pubspec.yaml apps/mobile/pubspec.lock
git commit -m "chore: add url_launcher ^6.3.1 dependency"
```

---

## Task 3: Update DonorOrgSetupScreen

**Files:**
- Modify: `apps/mobile/lib/features/donor/presentation/screens/donor_org_setup_screen.dart`
- Modify: `apps/mobile/test/widget/features/donor/donor_org_setup_screen_test.dart`

- [ ] **Step 3.1 — Write 4 failing tests**

Add these test cases to `apps/mobile/test/widget/features/donor/donor_org_setup_screen_test.dart`.

First, add imports and fake classes at the top (after the existing imports):

```dart
import 'package:geolocator/geolocator.dart';

// ── Geolocator fakes ──────────────────────────────────────────────────────────

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  final bool permissionDenied;
  _FakeGeolocatorPlatform({this.permissionDenied = false});

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (permissionDenied) throw const PermissionDeniedException('denied');
    return Position(
      latitude: 13.7563,
      longitude: 100.5018,
      timestamp: DateTime(2026, 6, 4),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
}

// ── Capturing fake ────────────────────────────────────────────────────────────

class _CapturingDonorAccountRepository implements DonorAccountRepository {
  UserProfileUpdate? lastUpdate;

  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {
    lastUpdate = update;
  }

  @override
  Future<DonorProfile?> getUser(String uid) async => null;
}
```

Then add a `setUp` / `tearDown` block inside the existing `group('DonorOrgSetupScreen', ...)` (before the first `testWidgets`):

```dart
setUp(() {
  GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
});
```

Then add these 4 new `testWidgets` calls at the end of the group (before the closing `}`):

```dart
    testWidgets('map button disabled when address empty and no coords', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final mapBtn = find.byIcon(Icons.map_outlined);
      await tester.ensureVisible(mapBtn);
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(mapBtn).onPressed, isNull);
    });

    testWidgets('map button enabled after entering address text', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Street Address'),
        '123 Sukhumvit Rd, Bangkok',
      );
      await tester.pump();

      final mapBtn = find.byIcon(Icons.map_outlined);
      await tester.ensureVisible(mapBtn);
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(mapBtn).onPressed, isNotNull);
    });

    testWidgets('location button shows snackbar on permission denied', (
      tester,
    ) async {
      GeolocatorPlatform.instance =
          _FakeGeolocatorPlatform(permissionDenied: true);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final locationBtn = find.byIcon(Icons.my_location);
      await tester.ensureVisible(locationBtn);
      await tester.pumpAndSettle();
      await tester.tap(locationBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'Location permission denied. Please enter your address manually.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Complete Setup sends lat/lng in UserProfileUpdate', (
      tester,
    ) async {
      final capturingRepo = _CapturingDonorAccountRepository();
      await tester.pumpWidget(_buildApp(repo: capturingRepo));
      await tester.pumpAndSettle();

      // Tap location button to populate coords
      final locationBtn = find.byIcon(Icons.my_location);
      await tester.ensureVisible(locationBtn);
      await tester.pumpAndSettle();
      await tester.tap(locationBtn);
      await tester.pumpAndSettle();

      // Fill required org name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Organization / Store Name'),
        'FreshMart',
      );

      final saveBtn = find.widgetWithText(FilledButton, 'Complete Setup');
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(capturingRepo.lastUpdate?.latitude, closeTo(13.7563, 0.0001));
      expect(capturingRepo.lastUpdate?.longitude, closeTo(100.5018, 0.0001));
    });
```

- [ ] **Step 3.2 — Run tests to verify they fail**

```bash
cd apps/mobile
flutter test test/widget/features/donor/donor_org_setup_screen_test.dart --no-pub 2>&1 | tail -20
```

Expected: compile error or failures on the 4 new cases because `Icons.map_outlined` and `Icons.my_location` don't exist in the screen yet.

- [ ] **Step 3.3 — Update `donor_org_setup_screen.dart`**

Replace the full file content with the following. Key changes: new state fields, `_fetchLocation()`, `_openInMaps()`, `_buildAddressSuffixIcon()`, address listener, updated `_save()`, and `_inputDecoration` now accepts optional `suffixIcon`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/features/donor/presentation/providers/donor_account_provider.dart';
import 'package:saveameal/shared/theme/app_colors.dart';
import 'package:saveameal/shared/theme/spacing.dart';
import 'package:saveameal/shared/widgets/save_a_meal_logo.dart';
import 'package:url_launcher/url_launcher.dart';

class DonorOrgSetupScreen extends ConsumerStatefulWidget {
  const DonorOrgSetupScreen({super.key});

  @override
  ConsumerState<DonorOrgSetupScreen> createState() =>
      _DonorOrgSetupScreenState();
}

class _DonorOrgSetupScreenState extends ConsumerState<DonorOrgSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _managerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  static const _surplusOptions = [
    'Bakery',
    'Produce',
    'Dairy',
    'Non-Perishable',
  ];
  final Set<String> _selectedSurplusTypes = {};

  bool _saving = false;
  bool _fetchingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _orgNameController.dispose();
    _managerController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onAddressChanged() => setState(() {});

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } on PermissionDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission denied. Please enter your address manually.',
            ),
          ),
        );
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission denied. Please enter your address manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _openInMaps() async {
    final Uri uri;
    if (_latitude != null && _longitude != null) {
      uri = Uri.parse('https://maps.google.com/?q=$_latitude,$_longitude');
    } else {
      final encoded = Uri.encodeComponent(_addressController.text.trim());
      uri = Uri.parse('https://maps.google.com/?q=$encoded');
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps.')),
      );
    }
  }

  Widget _buildAddressSuffixIcon(ColorScheme cs) {
    final canOpenMaps =
        _addressController.text.isNotEmpty || _latitude != null;
    return SizedBox(
      width: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_fetchingLocation)
            Padding(
              padding: const EdgeInsets.all(Spacing.sm + 2),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
            )
          else
            IconButton(
              iconSize: 20,
              icon: Icon(Icons.my_location, color: cs.primary),
              tooltip: 'Use current location',
              onPressed: () => _fetchLocation(),
            ),
          IconButton(
            iconSize: 20,
            icon: Icon(
              Icons.map_outlined,
              color: canOpenMaps
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.38),
            ),
            tooltip: 'Open in Maps',
            onPressed: canOpenMaps ? () => _openInMaps() : null,
          ),
        ],
      ),
    );
  }

  Future<void> _save(String uid) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(updateUserUsecaseProvider).call(
        uid,
        UserProfileUpdate(
          orgName: _orgNameController.text.trim(),
          managerName: _managerController.text.trim().isEmpty
              ? null
              : _managerController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          streetAddress: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          surplusTypes: _selectedSurplusTypes.toList(),
          latitude: _latitude,
          longitude: _longitude,
        ),
      );
      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/donor');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ac = Theme.of(context).extension<AppColors>()!;

    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: SaveAMealLogo(size: 48)),
                const SizedBox(height: Spacing.md),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(done: true, active: false, cs: cs),
                    _StepConnector(cs: cs),
                    _StepDot(done: false, active: true, cs: cs),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Step 2 of 2',
                  textAlign: TextAlign.center,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: Spacing.md),

                Text(
                  'Set Up Your Organization',
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Tell us about your store so beneficiaries\nand drivers can find you.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.xl),

                TextFormField(
                  controller: _orgNameController,
                  decoration: _inputDecoration(
                    context,
                    'Organization / Store Name',
                  ),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: Spacing.md),

                TextFormField(
                  controller: _managerController,
                  decoration: _inputDecoration(context, 'Manager Name'),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: Spacing.md),

                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration(context, 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: Spacing.md),

                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration(
                    context,
                    'Street Address',
                    suffixIcon: _buildAddressSuffixIcon(cs),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: Spacing.xl),

                Text(
                  'What type of food do you donate?',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Select all that apply.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.xs,
                  runSpacing: Spacing.xs,
                  children: _surplusOptions.map((type) {
                    final selected = _selectedSurplusTypes.contains(type);
                    return FilterChip(
                      label: Text(type),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedSurplusTypes.add(type);
                        } else {
                          _selectedSurplusTypes.remove(type);
                        }
                      }),
                      selectedColor: ac.brand.withValues(alpha: 0.15),
                      checkmarkColor: ac.brand,
                    );
                  }).toList(),
                ),
                const SizedBox(height: Spacing.xl),

                FilledButton(
                  onPressed: (_saving || uid.isEmpty) ? null : () => _save(uid),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                    backgroundColor: cs.primary,
                  ),
                  child: _saving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Text(
                          'Complete Setup',
                          style: tt.titleMedium?.copyWith(color: cs.onPrimary),
                        ),
                ),
                const SizedBox(height: Spacing.sm),

                TextButton(
                  onPressed: _saving ? null : () => context.go('/donor'),
                  child: Text(
                    'Skip for now',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done, required this.active, required this.cs});

  final bool done;
  final bool active;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final filled = done || active;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? cs.primary : cs.surfaceContainerHigh,
      ),
      child: done
          ? Icon(Icons.check, size: 14, color: cs.onPrimary)
          : active
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.onPrimary,
                ),
              ),
            )
          : null,
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) =>
      Container(width: 40, height: 2, color: cs.primary);
}

InputDecoration _inputDecoration(
  BuildContext context,
  String label, {
  Widget? suffixIcon,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    suffixIcon: suffixIcon,
    labelStyle: TextStyle(color: cs.onSurfaceVariant),
    filled: true,
    fillColor: cs.surfaceContainerLowest,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: Spacing.md,
      vertical: Spacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.31)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.31)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: cs.error, width: 1.5),
    ),
  );
}
```

- [ ] **Step 3.4 — Run all tests in the file**

```bash
cd apps/mobile
flutter test test/widget/features/donor/donor_org_setup_screen_test.dart --no-pub
```

Expected: `+19: All tests passed!` (15 existing + 4 new).

- [ ] **Step 3.5 — Commit**

```bash
cd apps/mobile && dart format . && cd ../..
git add apps/mobile/lib/features/donor/presentation/screens/donor_org_setup_screen.dart \
        apps/mobile/test/widget/features/donor/donor_org_setup_screen_test.dart
git commit -m "feat(donor): add location + maps buttons to DonorOrgSetupScreen address field"
```

---

## Task 4: Update OrganizationProfileScreen

**Files:**
- Modify: `apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart`
- Modify: `apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart`

- [ ] **Step 4.1 — Write 5 failing tests**

In `apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart`, add these imports after the existing imports:

```dart
import 'package:geolocator/geolocator.dart';
```

Add the geolocator fakes after the existing fake classes (before the router helper):

```dart
class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  final bool permissionDenied;
  _FakeGeolocatorPlatform({this.permissionDenied = false});

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (permissionDenied) throw const PermissionDeniedException('denied');
    return Position(
      latitude: 13.7563,
      longitude: 100.5018,
      timestamp: DateTime(2026, 6, 4),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
}

class _CapturingDonorAccountRepository implements DonorAccountRepository {
  UserProfileUpdate? lastUpdate;

  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {
    lastUpdate = update;
  }

  @override
  Future<DonorProfile?> getUser(String uid) async => DonorProfile(
    uid: uid,
    name: 'FreshMart Supermarket',
    email: 'freshmart@test.com',
    role: 'donor',
    streetAddress: '123 Test Street, Bangkok',
  );
}

class _ProfileWithCoordsDonorAccountRepository
    implements DonorAccountRepository {
  @override
  Future<void> updateUser(String uid, UserProfileUpdate update) async {}

  @override
  Future<DonorProfile?> getUser(String uid) async => DonorProfile(
    uid: uid,
    name: 'FreshMart Supermarket',
    email: 'freshmart@test.com',
    role: 'donor',
    streetAddress: '123 Test Street, Bangkok',
    latitude: 13.7563,
    longitude: 100.5018,
  );
}
```

Add a `setUp` block inside the existing `group('OrganizationProfileScreen', ...)` (before the first `testWidgets`):

```dart
setUp(() {
  GeolocatorPlatform.instance = _FakeGeolocatorPlatform();
});
```

Add these 5 new `testWidgets` calls at the end of the group (before the closing `}`):

```dart
    testWidgets('map button disabled when address empty and no stored coords', (
      tester,
    ) async {
      // Use a repo that returns no coords and no address
      final noAddrRepo = _FakeDonorAccountRepository(); // returns streetAddress: '123 Test Street'
      // Override with a version that has no address
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_testUser)),
            currentUserProvider.overrideWith(
              (ref) async => const DonorProfile(
                uid: 'abcdef1234567890',
                name: 'FreshMart Supermarket',
                email: 'freshmart@test.com',
                role: 'donor',
              ),
            ),
            updateUserUsecaseProvider.overrideWithValue(
              UpdateUserUsecase(noAddrRepo),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light(),
            routerConfig: _buildRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mapBtn = find.byIcon(Icons.map_outlined);
      await tester.scrollUntilVisible(mapBtn, 150);
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(mapBtn).onPressed, isNull);
    });

    testWidgets('map button enabled when profile has stored coordinates', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(repo: _ProfileWithCoordsDonorAccountRepository()));
      await tester.pumpAndSettle();

      final mapBtn = find.byIcon(Icons.map_outlined);
      await tester.scrollUntilVisible(mapBtn, 150);
      await tester.pumpAndSettle();

      expect(tester.widget<IconButton>(mapBtn).onPressed, isNotNull);
    });

    testWidgets('location button shows snackbar on permission denied', (
      tester,
    ) async {
      GeolocatorPlatform.instance =
          _FakeGeolocatorPlatform(permissionDenied: true);

      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final locationBtn = find.byIcon(Icons.my_location);
      await tester.scrollUntilVisible(locationBtn, 150);
      await tester.pumpAndSettle();
      await tester.tap(locationBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text(
          'Location permission denied. Please enter your address manually.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Save Changes sends lat/lng in UserProfileUpdate', (
      tester,
    ) async {
      final capturingRepo = _CapturingDonorAccountRepository();
      await tester.pumpWidget(_buildApp(repo: capturingRepo));
      await tester.pumpAndSettle();

      final locationBtn = find.byIcon(Icons.my_location);
      await tester.scrollUntilVisible(locationBtn, 150);
      await tester.pumpAndSettle();
      await tester.tap(locationBtn);
      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(FilledButton, 'Save Changes');
      await tester.scrollUntilVisible(saveBtn, 150);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(capturingRepo.lastUpdate?.latitude, closeTo(13.7563, 0.0001));
      expect(capturingRepo.lastUpdate?.longitude, closeTo(100.5018, 0.0001));
    });

    testWidgets('pre-fills lat/lng from existing profile', (tester) async {
      await tester.pumpWidget(
        _buildApp(repo: _ProfileWithCoordsDonorAccountRepository()),
      );
      await tester.pumpAndSettle();

      // Map button enabled proves coords were pre-loaded from profile
      final mapBtn = find.byIcon(Icons.map_outlined);
      await tester.scrollUntilVisible(mapBtn, 150);
      await tester.pumpAndSettle();
      expect(tester.widget<IconButton>(mapBtn).onPressed, isNotNull);
    });
```

- [ ] **Step 4.2 — Run tests to verify new cases fail**

```bash
cd apps/mobile
flutter test test/widget/features/donor/organization_profile_screen_test.dart --no-pub 2>&1 | tail -20
```

Expected: compile error or test failures on the 5 new cases because `Icons.map_outlined` / `Icons.my_location` don't exist in the screen yet.

- [ ] **Step 4.3 — Update `organization_profile_screen.dart` state fields and methods**

In `_OrganizationProfileScreenState`, add these fields alongside the existing `bool _saving = false` and `bool _initialized = false`:

```dart
  bool _fetchingLocation = false;
  double? _latitude;
  double? _longitude;
```

Add listener registration in `initState` (which doesn't exist yet — add it):

```dart
  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
  }
```

In `dispose()`, add before `super.dispose()`:

```dart
    _addressController.removeListener(_onAddressChanged);
```

Add three new methods to the state class (after `_doneEditingHours`):

```dart
  void _onAddressChanged() => setState(() {});

  Future<void> _fetchLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } on PermissionDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission denied. Please enter your address manually.',
            ),
          ),
        );
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission denied. Please enter your address manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _openInMaps() async {
    final Uri uri;
    if (_latitude != null && _longitude != null) {
      uri = Uri.parse('https://maps.google.com/?q=$_latitude,$_longitude');
    } else {
      final encoded = Uri.encodeComponent(_addressController.text.trim());
      uri = Uri.parse('https://maps.google.com/?q=$encoded');
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps.')),
      );
    }
  }

  Widget _buildAddressSuffixIcon(ColorScheme cs) {
    final canOpenMaps =
        _addressController.text.isNotEmpty || _latitude != null;
    return SizedBox(
      width: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_fetchingLocation)
            Padding(
              padding: const EdgeInsets.all(Spacing.sm + 2),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
            )
          else
            IconButton(
              iconSize: 20,
              icon: Icon(Icons.my_location, color: cs.primary),
              tooltip: 'Use current location',
              onPressed: () => _fetchLocation(),
            ),
          IconButton(
            iconSize: 20,
            icon: Icon(
              Icons.map_outlined,
              color: canOpenMaps
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.38),
            ),
            tooltip: 'Open in Maps',
            onPressed: canOpenMaps ? () => _openInMaps() : null,
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 4.4 — Add imports to `organization_profile_screen.dart`**

At the top of the file, add these two imports after the existing imports:

```dart
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
```

- [ ] **Step 4.5 — Pre-fill lat/lng in the existing pre-fill block**

Find the pre-fill block inside `build()` (around `if (!_initialized && userModel != null)`). Add two lines after the existing pre-fill assignments:

```dart
      _bannerUrl = userModel.bannerUrl;
      _selectedSurplusTypes = Set.from(userModel.surplusTypes);
      // ADD THESE TWO LINES:
      _latitude = userModel.latitude;
      _longitude = userModel.longitude;
      final hours = userModel.operatingHours.isNotEmpty
```

- [ ] **Step 4.6 — Pass `addressSuffixIcon` to `_StoreDetailsCard`**

In `_StoreDetailsCard`'s constructor and field list, add one parameter:

```dart
class _StoreDetailsCard extends StatelessWidget {
  const _StoreDetailsCard({
    required this.nameController,
    required this.managerController,
    required this.phoneController,
    required this.addressController,
    required this.emailText,
    required this.textTheme,
    required this.onNameChanged,
    this.addressSuffixIcon,         // ADD THIS
  });

  final TextEditingController nameController;
  final TextEditingController managerController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final String emailText;
  final TextTheme textTheme;
  final VoidCallback onNameChanged;
  final Widget? addressSuffixIcon;  // ADD THIS
```

Inside `_StoreDetailsCard.build`, update the Street Address `TextFormField` decoration:

```dart
          TextFormField(
            controller: addressController,
            decoration: InputDecoration(
              labelText: 'Street Address',
              border: const OutlineInputBorder(),
              suffixIcon: addressSuffixIcon,    // ADD THIS
            ),
            maxLines: 3,
          ),
```

- [ ] **Step 4.7 — Pass suffix icon from build() to `_StoreDetailsCard`**

Find the `_StoreDetailsCard(...)` call in `build()` and add the new parameter:

```dart
              _StoreDetailsCard(
                nameController: _nameController,
                managerController: _managerController,
                phoneController: _phoneController,
                addressController: _addressController,
                emailText: emailText,
                textTheme: textTheme,
                onNameChanged: () => setState(() {}),
                addressSuffixIcon: _buildAddressSuffixIcon(cs),  // ADD THIS
              ),
```

- [ ] **Step 4.8 — Add lat/lng to `_save()` in `OrganizationProfileScreen`**

Inside `_save(String uid)`, add `latitude` and `longitude` to the `UserProfileUpdate` call:

```dart
      await ref
          .read(updateUserUsecaseProvider)
          .call(
            uid,
            UserProfileUpdate(
              orgName: _nameController.text.trim(),
              managerName: _managerController.text.trim(),
              phone: _phoneController.text.trim(),
              streetAddress: _addressController.text.trim(),
              operatingHours: _operatingHours,
              surplusTypes: _selectedSurplusTypes.toList(),
              bannerUrl: _bannerUrl,
              latitude: _latitude,    // ADD THIS
              longitude: _longitude,  // ADD THIS
            ),
          );
```

- [ ] **Step 4.9 — Run all tests in the file**

```bash
cd apps/mobile
flutter test test/widget/features/donor/organization_profile_screen_test.dart --no-pub
```

Expected: all tests pass (existing + 5 new). If any existing tests fail, check that the `_StoreDetailsCard` changes didn't break rendering of fields that tests reference.

- [ ] **Step 4.10 — Commit**

```bash
cd apps/mobile && dart format . && cd ../..
git add apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart \
        apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart
git commit -m "feat(donor): add location + maps buttons to OrganizationProfileScreen address field"
```

---

## Task 5: Final verification

- [ ] **Step 5.1 — Run full test suite**

```bash
cd apps/mobile
flutter test --no-pub
```

Expected: all tests pass, 0 failures.

- [ ] **Step 5.2 — Run static analysis**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 5.3 — Format check**

```bash
dart format --output=none --set-exit-if-changed .
```

Expected: exit code 0 (no files need formatting). If any files are reported, run `dart format .` and commit.
