# Security Reviewer - 2026-06-03 - donor-account-screens

**Reviewer:** security-reviewer
**Session ID:** donor-account-screens
**PR / Branch:** feature/donor-account-screens
**Date:** 2026-06-03

---

## Summary

Three new donor account screens and Clean Architecture plumbing were reviewed. The auth boundary is sound: uid is always sourced from authStateProvider. Four issues block merge: a Google Maps API key hardcoded in platform source, Firestore update rule lacking a field allowlist enabling role escalation, Storage rules missing a users/ path leaving uploads broken, and iOS missing privacy usage strings. No PII is logged. Widget tests exist for all three screens.

---

## Findings

### Critical (block merge)

- Hardcoded Google Maps API key: apps/mobile/android/app/src/main/AndroidManifest.xml line 31 and apps/mobile/ios/Runner/AppDelegate.swift line 11 both embed the literal key AIzaSyDk0nptxIoDGIYOYhYplzEW3t8simNv9Rw. CWE-312. Required fix: revoke immediately in Google Cloud Console, generate a replacement with Android SHA-1 and iOS bundle ID restrictions, inject via --dart-define=MAPS_API_KEY=... or a gitignored secrets file substituted by CI/CD.

### High (fix before release)

- No Storage Security Rule for users/ paths: storage.rules missing match for users/{uid}/. The catch-all deny rule makes uploadProfilePhoto and uploadBannerPhoto throw permission-denied in production. CWE-284. Required fix: add owner-only write rule with 5 MB size cap and image content-type check.

- Firestore update rule allows arbitrary field writes including role: firestore.rules line 27 has no field allowlist. A donor can self-assign role driver. CWE-285. Required fix: add hasOnly allowlist of permitted fields and role immutability invariant.

- iOS Info.plist missing privacy usage strings: NSLocationWhenInUseUsageDescription, NSPhotoLibraryUsageDescription, NSPhotoLibraryAddUsageDescription absent. iOS hard-crashes without these. Required fix: add all three keys.

### Medium (changes requested)

- No client-side size guard before readAsBytes(): a large image causes OOM before the server 5 MB rule applies. CWE-400. Recommended fix: check photo.length() first or use ref.putFile to stream.

- getPositionStream() exported with no cancellation contract and not consumed by any screen in this PR. Future misuse leaks location PII. Recommended fix: remove until a concrete use case exists.

- Raw exception stringified in SnackBar at personal_information_screen.dart line 360 and organization_profile_screen.dart line 155. May expose Firestore path details. Recommended fix: map to friendly strings.

### Informational

- Auth boundary sound: uid always from authStateProvider, never a route parameter. Benign.
- Location permissions proportionate: foreground-only, medium accuracy, one-shot use. Benign.
- Firebase options keys pre-existing public identifiers. Confirm platform restrictions in Firebase console.
- Widget tests present for all three screens. Mandatory-test rule satisfied.
- Domain layer clean: zero Flutter or backend imports. Benign.

---

## Checklist

- [x] No API keys hardcoded in new .dart files
- [ ] Google Maps API key hardcoded in AndroidManifest.xml and AppDelegate.swift (Critical)
- [x] flutter_secure_storage declared; no new credential persistence
- [x] uid always from authStateProvider
- [ ] Firestore update rule lacks field allowlist; role escalation possible (High)
- [ ] Storage rules missing users/ path; uploads broken (High)
- [ ] iOS Info.plist missing privacy usage strings (High)
- [ ] No client-side size guard before readAsBytes() (Medium)
- [x] No PII logged in new screens
- [x] No background location permission
- [x] Widget tests present for all three screens

---

## Verdict

**BLOCKED**

Reason: A Google Maps API key is committed in plaintext to two platform source files (CWE-312, Critical) and must be revoked and rotated before merge; the three High-severity issues (Storage rules missing for users/ paths, Firestore update rule permitting role self-escalation, iOS missing privacy usage strings) must also be resolved.
