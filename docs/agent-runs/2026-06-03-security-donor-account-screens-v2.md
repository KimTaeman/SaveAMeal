# Security Reviewer - 2026-06-03 - donor-account-screens (v2 re-review)

**Reviewer:** security-reviewer
**Session ID:** donor-account-screens-v2
**PR / Branch:** feature/donor-account-screens
**Date:** 2026-06-03
**Re-review of:** docs/agent-runs/2026-06-03-security-donor-account-screens.md

---

## Summary

This is a re-review following the v1 BLOCKED verdict. Four issues were originally raised: a hardcoded Google Maps API key (Critical), missing Firestore update field allowlist (High), missing Firebase Storage rules for the users/ path (High), and missing iOS privacy usage strings (High). One Medium item (raw exception stringified in SnackBars) was also outstanding.

After examining all current file states:

- iOS privacy strings: FIXED.
- SnackBar raw-exception leakage: FIXED.
- Firestore field allowlist gap: UNRESOLVED.
- Firebase Storage users/ path rule gap: UNRESOLVED.
- Google Maps API key hardcoded: UNRESOLVED (pre-existing, not introduced by this PR).

The UserProfileUpdate typed entity and the .set(merge: true) change are net-neutral on server-side security posture. The firebase_auth direct import removal from DonorAccountScreen is correctly resolved. No new issues were introduced by this PR.

The PR should move from BLOCKED to CHANGES REQUESTED. The Maps key is a pre-existing repository issue; blocking this feature branch for it is disproportionate. The two server-side rule gaps must be resolved before merge.

---

## Finding Resolution Table

| Finding | v1 Severity | Status | Action Required |
|---|---|---|---|
| Google Maps API key hardcoded in AndroidManifest.xml:32 and AppDelegate.swift:11 | Critical | UNRESOLVED (pre-existing, not this PR) | Track in dedicated issue; revoke and rotate with platform restrictions; inject via CI secret |
| Firestore /users/{userId} update rule - no field allowlist (role escalation) | High | UNRESOLVED | Add hasOnly allowlist + role immutability guard |
| Firebase Storage - no rule for users/{uid}/ paths (uploads broken in production) | High | UNRESOLVED | Add owner-only write rule with size and content-type check |
| iOS Info.plist missing privacy usage strings | High | FIXED | No action required |
| Raw exception message stringified in SnackBar | Medium | FIXED | No action required |
| firebase_auth direct import in DonorAccountScreen | Informational | FIXED | No action required |

---

## Detailed Findings

### High (fix before merge)

- Firestore /users/{userId} update rule -- no field allowlist (firestore.rules lines 24-29). A signed-in user can write any field to their own document, including role. A donor can call the Firestore REST API directly with {role: driver} and immediately gain driver privileges. CWE-285 (Improper Authorization). The UserProfileUpdate.toMap() Dart-layer change is irrelevant -- it controls nothing server-side. Required fix: replace the bare allow update with a field allowlist and a role immutability invariant.

    allow update: if isSignedIn() && uid() == userId
                  && request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly([name,phone,location,photoUrl,orgName,
                                 managerName,streetAddress,bannerUrl,
                                 operatingHours,surplusTypes,fcmToken,updatedAt])
                  && request.resource.data.role == resource.data.role;

- Firebase Storage -- no rule for users/{uid}/ paths (storage.rules). No match block for users/{uid}/{allPaths=**} exists. The catch-all deny rule at lines 30-32 rejects every call to uploadProfilePhoto() and uploadBannerPhoto() in StorageService. All avatar and banner saves will throw permission-denied in production. CWE-284 (Improper Access Control). Required fix, inserted before the catch-all deny:

    match /users/{uid}/{allPaths=**} {
      allow read:  if request.auth != null;
      allow write: if request.auth != null
                   && request.auth.uid == uid
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches(image/.*);
    }

### Informational

- Google Maps API key (AIzaSyDk0nptxIoDGIYOYhYplzEW3t8simNv9Rw) remains hardcoded in AndroidManifest.xml line 32 and AppDelegate.swift line 11. CWE-312. Pre-dates this PR by multiple commits. Recommended path: revoke immediately in Google Cloud Console, generate a replacement with Android SHA-1 and iOS bundle ID restrictions, inject via --dart-define or a CI-managed gitignored substitution. Track as a separate high-priority issue; resolve before any public release.

- firebase_options.dart contains Firebase Web/Android/iOS API keys. Standard FlutterFire CLI output and accepted for client-side Firebase identifiers. Confirm App Check and domain/platform restrictions are enabled in the Firebase console.

- UserProfileUpdate is pure Dart with zero Flutter/Firebase imports. toMap() is called only at the datasource boundary in DonorAccountRemoteDatasourceImpl. Does not change server-side security posture.

- .set(merge: true) vs .update(): both are subject to identical Firestore Security Rules evaluation. The merge strategy change does not open or close any server-side permission gap. The role escalation risk is unchanged.

- SnackBar error messages are now FirebaseException-aware across personal_information_screen.dart and organization_profile_screen.dart. One copy-text note: in _getLocation the FirebaseException branch reads Upload failed -- location errors are never FirebaseExceptions so this branch is unreachable. Harmless but confusing during debugging.

- getPositionStream() remains on LocationService and is not consumed by any screen in this PR. The v1 recommendation to remove it until concretely needed still stands.

- Auth boundary remains sound: uid is always sourced from authStateProvider, never a route parameter or user-supplied string.

- No PII logged in any of the three screens. Widget tests exist for all three screens.

---

## Secret Management Checklist

- [x] No API keys hardcoded in new .dart files introduced by this PR
- [x] Firebase options keys are FlutterFire CLI output (accepted client-side identifiers)
- [ ] Google Maps API key in AndroidManifest.xml and AppDelegate.swift -- pre-existing, tracked separately
- [x] .env files gitignored
- [x] flutter_secure_storage declared in pubspec for credential persistence
- [x] No new plaintext secrets introduced by this PR

---

## Verdict

**CHANGES REQUESTED**

Two server-side rule gaps must be resolved before merge: Firestore update rule with no field allowlist enabling role self-escalation (CWE-285, High) and Firebase Storage missing a users/ write rule making all avatar and banner uploads broken in production (CWE-284, High). The Google Maps API key is a pre-existing repository issue not introduced by this PR; downgrading from BLOCKED to CHANGES REQUESTED is appropriate, but the key must be tracked and remediated urgently in a dedicated commit against main before any public release.
