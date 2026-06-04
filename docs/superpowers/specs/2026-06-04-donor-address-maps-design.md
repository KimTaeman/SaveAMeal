# Design: Donor Address → Google Maps Link

**Date:** 2026-06-04  
**Status:** APPROVED  
**Scope:** `DonorOrgSetupScreen`, `OrganizationProfileScreen`

---

## Problem

The donor's `streetAddress` is stored as a plain string with no coordinates. Drivers cannot programmatically navigate to a pickup location, and donors have no way to verify their address is accurate on a map.

## Goal

Store `latitude` and `longitude` alongside the donor's street address so the driver flow can use real coordinates for pickup navigation later. Give donors two in-form affordances: a one-tap current-location fill and a maps verification button.

---

## Section 1 — Data Layer

### Files changed

| Action | File |
|---|---|
| Modify | `lib/core/models/user_model.dart` |
| Modify | `lib/features/donor/domain/entities/donor_profile.dart` |
| Modify | `lib/features/donor/domain/entities/user_profile_update.dart` |
| Modify | `lib/features/donor/data/datasources/donor_account_remote_datasource.dart` |
| Modify | `lib/features/donor/data/repositories/donor_account_repository_impl.dart` |

### `UserModel` (Freezed)

Add two nullable fields:

```dart
double? latitude,
double? longitude,
```

Run `dart run build_runner build --delete-conflicting-outputs` after.

### `DonorProfile` (pure Dart entity)

```dart
final double? latitude;
final double? longitude;
```

### `UserProfileUpdate` (pure Dart entity)

```dart
final double? latitude;
final double? longitude;
```

### `_toFirestoreMap()` in datasource

```dart
if (u.latitude != null) 'latitude': u.latitude,
if (u.longitude != null) 'longitude': u.longitude,
```

### `DonorAccountRepositoryImpl`

Forward the two new fields when mapping `UserModel → DonorProfile`.

### Firestore

No index changes. Fields stored flat on `users/{uid}` alongside `streetAddress`.

---

## Section 2 — UI Changes

### Both screens affected

- `lib/features/donor/presentation/screens/donor_org_setup_screen.dart`
- `lib/features/donor/presentation/screens/organization_profile_screen.dart`

### Address field layout

The street address `TextFormField` gains two icon buttons in its `suffixIcon`:

```
┌─────────────────────────────────────────────┬────┬────┐
│ Street Address                              │ 📍 │ 🗺 │
│ 123 Sukhumvit Rd, Bangkok                   │    │    │
└─────────────────────────────────────────────┴────┴────┘
```

`suffixIcon` receives a fixed-width `Row` containing both `IconButton`s.

### 📍 "Use current location" (`Icons.my_location`)

- Calls `Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)`
- On success:
  - Sets `_latitude`, `_longitude` in widget state
  - Fills `_addressController.text` with `"${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}"` (placeholder until reverse-geocoding is added)
- On `PermissionDeniedException` or `LocationServiceDisabledException`:
  - Shows `SnackBar`: *"Location permission denied. Please enter your address manually."*
- While fetching: replaces button with `SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))`
- State field: `bool _fetchingLocation = false`

### 🗺 "Open in Maps" (`Icons.map_outlined`)

- **Disabled** when `_addressController.text.isEmpty` AND `_latitude == null`
- On tap:
  - If coordinates exist: `https://maps.google.com/?q=<lat>,<lng>`
  - Otherwise: `https://maps.google.com/?q=<Uri.encodeComponent(address)>`
  - Opens via `launchUrl(uri, mode: LaunchMode.externalApplication)`
- On launch failure: `SnackBar` — *"Could not open Maps."*

### New dependency

```yaml
# pubspec.yaml
url_launcher: ^6.3.1
```

---

## Section 3 — Platform Setup & State

### AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### ios/Runner/Info.plist

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to set your store's pickup location.</string>
```

### Web

Handled automatically by `geolocator_web` via the browser permission dialog.

### New screen state fields (both screens)

```dart
double? _latitude;
double? _longitude;
bool _fetchingLocation = false;
```

`OrganizationProfileScreen` pre-fills on load:

```dart
_latitude = userModel.latitude;
_longitude = userModel.longitude;
```

### Save payload (both screens)

```dart
UserProfileUpdate(
  orgName: ...,
  ...
  latitude: _latitude,
  longitude: _longitude,
)
```

---

## Section 4 — Out of Scope

- **Reverse geocoding** — address field stays free text; coordinates are stored alongside it. A future spec adds the `geocoding` package to auto-fill the address after tapping 📍.
- **Batch pickup coordinates** — wiring `DonorProfile.latitude/longitude` into `Batch` when logging a batch. This spec only stores the coordinates; the batch-creation spec reads them.
- **Address validation** — no format or geocoding validation on the string.
- **Places Autocomplete** — deferred; not needed with the current-location approach.

---

## Section 5 — Test Plan

| Test file | Cases |
|---|---|
| `test/widget/features/donor/donor_org_setup_screen_test.dart` | ① Map button disabled when address empty + no coords; ② map button enabled after entering address; ③ location permission denied → snackbar; ④ lat/lng included in `UserProfileUpdate` on save |
| `test/widget/features/donor/organization_profile_screen_test.dart` | Same 4 cases; ⑤ pre-fill: lat/lng loaded from existing profile |

**Mocking strategy:**
- Geolocator: override `GeolocatorPlatform.instance` with a fake implementation
- url_launcher: mock via `url_launcher_platform_interface` `MockUrlLauncher`

---

## Checklist

- [ ] `UserModel` fields added + codegen run
- [ ] `DonorProfile` + `UserProfileUpdate` fields added
- [ ] Datasource map + repository impl updated
- [ ] `url_launcher` added to `pubspec.yaml`
- [ ] AndroidManifest permissions added
- [ ] Info.plist key added
- [ ] `DonorOrgSetupScreen` address field updated
- [ ] `OrganizationProfileScreen` address field updated
- [ ] Tests updated / added
- [ ] `flutter analyze` passes
- [ ] `dart format .` clean
