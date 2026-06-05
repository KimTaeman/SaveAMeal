# Security Review v4 — feature/batch-schema-consistency

**Reviewer:** security-reviewer
**Session ID:** batch-schema-v4
**PR / Branch:** feature/batch-schema-consistency
**Date:** 2026-06-05

---

## Verdict: APPROVED (with one pre-release action item)

All three prior blocking findings are confirmed resolved. No new blocking issues were introduced by the 28-file change set. One pre-existing high-severity finding (`firebase_options.dart` committed with live API keys) is noted as a pre-release action item but does not block this branch merge, as it predates this PR and is a project-wide concern.

---

## All blocking findings — resolved?

### v2 blockers

- `BatchStatus` duplicated in domain and data — RESOLVED. `batch_model.dart` imports from `package:saveameal/shared/domain/entities/batch_status.dart`. No duplicate definition found.
- `OrderHistoryEntry.displayId` computed in domain entity — RESOLVED. No `displayId` field present in domain entities; `formatBatchId()` is confirmed in `lib/shared/utils/batch_id_formatter.dart` and called only from presentation layer.
- Missing unit tests for `formatBatchId` and `FoodCategory.fromString` — RESOLVED. Both test files present and confirmed added in this PR.

### v3 blockers

- Google Maps API key hardcoded in `AppDelegate.swift` — RESOLVED. `AppDelegate.swift` line 11 reads: `GMSServices.provideAPIKey(Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String ?? "")`. `Info.plist` line 70 holds `$(MAPS_API_KEY)`, which is the correct Xcode build variable substitution syntax. The variable must be supplied via `MAPS_API_KEY=... flutter build ios` or set in the CI environment; it does not resolve from `local.properties` (that is Android-only). `Generated.xcconfig` (which is gitignored) is the mechanism Flutter uses to pass `--dart-define` values through to the Xcode build system — however, `$(MAPS_API_KEY)` in `Info.plist` is a standard Xcode build setting reference, not a `--dart-define`. Teams must set it as an Xcode User-Defined Build Setting or CI environment variable. This is the correct and standard approach for iOS; the fix is sound.
- `donorContact` PII denormalised in batch documents — RESOLVED. Zero references to `donorContact` found in `apps/mobile/` (all Dart source) or `tools/` (seed script). Remaining hits are in `docs/` historical plans and prior agent-run reports, which are read-only documentation and do not affect the running application.

---

## Remaining findings

### High (fix before release)

- `firebase_options.dart` committed with live Firebase API keys (five `AIzaSy…` values across web, android, ios, macos, windows platforms). CWE-312: Cleartext Storage of Sensitive Information. This file was committed in an earlier session (`5c397fb`) and is not part of this PR's changes.
  - Risk: Firebase API keys committed to a (presumably) non-private repository can be extracted by anyone with read access and used to send unauthenticated requests to Firebase endpoints. Firestore security rules are the primary control, but the keys also gate Firebase Auth and Storage.
  - Required fix before public release: add `firebase_options.dart` (or at minimum the `apiKey` values) to `.gitignore`, generate it at CI time using `flutterfire configure` with keys injected as CI secrets, and rotate the exposed keys in the Firebase Console. Note: Firebase web API keys are technically public-facing by design, but having them in a committed file alongside project ID and bucket URLs reduces friction for abuse. At minimum, ensure Firestore rules, App Check, and Firebase Auth authorised domains are hardened before release.

### Informational

- `$(MAPS_API_KEY)` resolves via Xcode build settings, not `--dart-define`. The CI pipeline and local developer setup guide must document that `MAPS_API_KEY` must be set as a User-Defined Build Setting or injected via `xcodebuild MAPS_API_KEY=…`. If it is not set, `Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY")` returns `nil` and Maps initialises with an empty string, silently disabling the map. The fallback `?? ""` is safe but produces no runtime error — add a startup assertion or log warning in non-production builds.
- `_extractBatchId("saveameal://batch/")` — bare URI with no trailing ID: `trimmed.substring(prefix.length)` returns an empty string `""`. `_validateAndNavigate` will then compare `activeBatch.id != ""`, which will always fail the equality check and show "Wrong QR code — try again." to the user. This is the correct safe-fail behaviour; no crash, no bypass. No fix required, but a unit test covering the empty-ID edge case is recommended.
- Demo password `qwer1234` appears in `tools/seed/seed.js` and `docs/DEMO_PREP.md`. This is intentional seed/demo data for a non-production Firebase environment and is not a credential for any production system. Not a blocker. Recommend rotating before any public demo with real shelter data.
- The 12 new optional fields added to the `Batch` entity (`beneficiaryName`, `beneficiaryAddress`, `donorName`, `pickupWindowStart`, `pickupWindowEnd`, `specialInstructions`, `pickupPhotoUrl`, `claimedAt`, `pickedUpAt`, `deliveredAt`, `deliveryNotes`) were reviewed for PII risk. `beneficiaryAddress` and `beneficiaryName` are PII. They are used in the driver flow to show delivery destination — verify Firestore security rules ensure only authenticated drivers with an active claim on a batch can read these fields. No Dart-layer concern; risk is at the rules layer.
- `auth_service.dart` passes `password` as a plain string argument to Firebase Auth SDK methods — this is standard and correct for Firebase Authentication; passwords are not logged or stored.

---

## Secret Management Checklist

- [x] No Maps API key hardcoded in `.dart` files — fixed in v3, confirmed
- [x] Maps key injected via `Info.plist` Xcode build variable `$(MAPS_API_KEY)`
- [ ] Firebase API keys not in `.dart` source — FAIL: `firebase_options.dart` committed with live keys (pre-existing, not this PR)
- [x] `.env` files gitignored — confirmed in root `.gitignore`
- [x] `flutter_secure_storage` in pubspec for credential persistence
- [x] `donorContact` PII fully removed from all live source and seed files
- [x] No new plaintext secrets introduced by this PR's 28 files

---

## Summary

The `feature/batch-schema-consistency` branch successfully addresses all findings from reviews v2 and v3. The Google Maps key injection is implemented correctly for iOS using the standard Xcode build variable mechanism. The `donorContact` PII field has been completely excised from all live Dart source and the seed script. The `_extractBatchId` function handles the empty-trailing-ID edge case safely with a non-crashing fail. No new secrets or PII were introduced by the 12 new `Batch` fields at the Dart layer. The one outstanding High finding (`firebase_options.dart` with committed Firebase keys) predates this PR and must be addressed as a project-wide action before public release, but does not block this branch.
