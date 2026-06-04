# Session: 2026-06-03 — driver-profile

**Date:** 2026-06-03  
**Member:** DeepseaMew  
**Agent:** flutter-engineer  
**Task:** Implement driver-profile feature per SPEC-0005

---

## Context

Scaffolded from approved PROP-0005 and SPEC-0005.  
Spec: [SPEC-0005](../../tech-specs/0005-driver-profile.md)  
Proposal: [PROP-0005](../../tech-proposals/0005-driver-profile.md)  
Figma: `LIdE6qDQzKpV3L5bAbO24w` (same file as SPEC-0004 driver flow, driver account frames)

All 13 stub files created. Three existing files need modification:  
- `lib/app/router.dart` — add `/driver/account` and `/driver/account/edit` routes  
- `lib/features/driver/presentation/screens/driver_map_screen.dart` — wire bottom nav index 2  
- `lib/main.dart` — add `Hive.openBox<dynamic>('driver_profile')` to `Future.wait`

## Plan

1. **Domain** — `DriverProfile` entity is done (stub). No Freezed needed here.
2. **Data models** — implement `DriverProfileModel` Freezed + JSON, run codegen.
3. **Datasources** — implement `DriverProfileRemoteDatasource` (Firestore + Firebase Storage) and `DriverProfileLocalDatasource` (Hive).
4. **Repository** — implement `DriverProfileRepositoryImpl` (remote-first, Hive fallback).
5. **Use cases** — wire through; contracts already defined.
6. **Provider** — implement `DriverProfileNotifier` (AsyncNotifier), run codegen.
7. **Screens** — `DriverAccountScreen` (read view) + `DriverEditProfileScreen` (edit form).
8. **Widget** — `DriverAvatarWidget` (CachedNetworkImage + tap-to-upload).
9. **Router** — add `/driver/account` and `/driver/account/edit` routes.
10. **Nav wiring** — extend `_DriverBottomNav.onDestinationSelected` to handle index 2.
11. **Hive init** — add `driver_profile` box to `main.dart` `Future.wait`.
12. **Tests** — widget tests for both screens + unit tests for use cases and repository impl.

## Progress

- [x] Stub files created (all 13)
- [x] Data model codegen (`driver_profile_model.freezed.dart`, `.g.dart`)
- [x] Provider codegen (`driver_profile_provider.g.dart`)
- [x] Remote datasource implemented
- [x] Local datasource implemented
- [x] Repository impl implemented
- [x] DriverAccountScreen implemented
- [x] DriverEditProfileScreen implemented
- [x] DriverAvatarWidget implemented
- [x] router.dart updated
- [x] driver_map_screen.dart bottom nav wired
- [x] main.dart Hive box added
- [x] Widget tests passing (driver_account_screen_test, driver_edit_profile_screen_test)
- [x] Unit tests passing (driver_profile_repository_test)
- [x] `flutter analyze` clean
- [x] `dart format .` clean

## Decisions Made

- `DriverProfile` entity uses a plain Dart class with a hand-written `copyWith` (no Freezed) — mirrors `DonorProfile` pattern, keeps domain layer codegen-free.
- Freezed is used only on `DriverProfileModel` in the data layer.
- `uploadAvatar` does NOT write the URL back to Firestore — the notifier composes `UploadAvatarUseCase` + `UpdateDriverProfileUseCase` to keep each use case single-responsibility.
- Hive box uses `dynamic` type (consistent with existing boxes) — no adapter registration needed.
- Firebase Storage path: `avatars/drivers/{uid}.jpg` (overwrites on each avatar change, no versioning).

## Blockers / Open Questions

- Firebase Storage SDK (`firebase_storage`) must be in `pubspec.yaml` — confirm it is already a dependency before implementing the remote datasource.
- `image_picker` package needed for avatar selection — confirm availability or add it.
- Auth uid provider: confirm the provider name that exposes the current user's uid (needed by `DriverProfileNotifier.build`).

## Handoff

Next agent (reviewer) needs to:
- Verify `DriverProfile` domain entity has zero Flutter/backend imports.
- Verify `DriverProfileRepository` abstract interface is in the domain layer only.
- Confirm Firestore write uses `SetOptions(merge: true)` — must not overwrite `points`, `role`, or auth fields.
- Check widget tests cover the offline empty state (provider returns null).

**Review needed from:** architect or qa-engineer
