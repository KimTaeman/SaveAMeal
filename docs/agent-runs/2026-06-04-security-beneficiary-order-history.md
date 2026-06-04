# Security Review — SPEC-0007 Beneficiary Order History
Date: 2026-06-04
Reviewer: security-reviewer
Branch: feat/beneficiary-order-history
Verdict: CHANGES REQUESTED

---

## Findings

### HIGH — Firestore `batches` read rule permits cross-user data access

**File:** `firestore.rules` line 34  
**CWE:** CWE-284 Improper Access Control

`allow read: if isSignedIn();` grants every authenticated user unrestricted read access to every batch document. The client-side `.where('beneficiaryId', isEqualTo: beneficiaryId)` filter in `fetchDeliveryHistoryPage` is enforced **only on the client**. Any authenticated user who knows or guesses another beneficiary's UID can bypass it via their own SDK query or a direct Firestore REST call.

The open-read intent is valid for `open`/`claimed`/`pickedUp` statuses (donors need the map view), but does not extend to `delivered`/`closed` batches which constitute personal delivery history.

**Required fix** — tighten the read rule:

```
allow read: if isSignedIn() && (
  resource.data.status in ['open', 'claimed', 'pickedUp'] ||
  resource.data.beneficiaryId == uid() ||
  resource.data.donorId      == uid() ||
  resource.data.driverId     == uid()
);
```

---

### HIGH — Firebase API keys committed to version control (pre-existing)

**File:** `apps/mobile/lib/firebase_options.dart` lines 43–85  
**CWE:** CWE-798 Hard-coded Credentials / CWE-312 Cleartext Storage

Web (`AIzaSyBZyFUR_ybM3pfW9J2d_E1CCHGjJRubno8`), Android, and iOS Firebase API keys are hardcoded in a generated file tracked by git. When combined with the open `batches` read rule, the web key enables unauthenticated REST enumeration via `https://firestore.googleapis.com/v1/projects/saveameal-87187/databases/(default)/documents/...`.

Pre-existing but must be remediated — add `firebase_options.dart` to `.gitignore`; regenerate via `flutterfire configure` in CI from a secret.

---

### MEDIUM — `cursor as DocumentSnapshot` unsafe hard cast

**File:** `apps/mobile/lib/services/firestore_service.dart` line 470  
**CWE:** CWE-704 Incorrect Type Conversion

```dart
query = query.startAfterDocument(cursor as DocumentSnapshot);
```

No `is DocumentSnapshot` guard. Within current code the cursor always originates from `snapshot.docs.last` (correct type), but the abstraction is fragile — a future refactor passing a different type will produce an unhandled `TypeError`.

**Recommended fix:**
```dart
if (cursor != null) {
  if (cursor is! DocumentSnapshot) {
    throw ArgumentError('cursor must be a DocumentSnapshot, got ${cursor.runtimeType}');
  }
  query = query.startAfterDocument(cursor);
}
```

---

### MEDIUM — No role guard on `/beneficiary/history` route

**File:** `apps/mobile/lib/app/router.dart` lines 177–184  
**CWE:** CWE-284 Improper Access Control

The `/donor` parent route enforces role via a `redirect` callback; the `/beneficiary` parent does not. Any authenticated donor or driver can navigate to `/beneficiary/history`. Results will be empty for non-beneficiary UIDs but the role boundary is not enforced at the router layer.

**Recommended fix:** add `redirect` to the `/beneficiary` route:
```dart
redirect: (context, state) {
  final user = ref.read(authStateProvider).asData?.value;
  if (user == null) return '/login';
  if (user.role != UserRole.beneficiary) return '/role-router';
  return null;
},
```

---

### MEDIUM — Hive `delivery_history_cache` not cleared on logout; `donorName` stored in plaintext

**Files:** `apps/mobile/lib/main.dart` line 42; `delivery_history_notifier.dart` lines 68, 130, 163, 210  
**CWE:** CWE-312 Cleartext Storage; CWE-459 Incomplete Cleanup

The box is opened without a cipher. JSON stored includes `donorName`. The `signOut()` flow does not clear the Hive cache — stale entries persist on-disk indefinitely under the previous user's UID prefix. `flutter_secure_storage` is declared in `pubspec.yaml` as the project's secrets mechanism but is unused for this box.

**Required fix (two parts):**
1. Clear `delivery_history_cache` entries on logout in `SignOutUsecase.call()` or `AuthRemoteDatasourceImpl.signOut()`.
2. Defence-in-depth: open the box with a `HiveAesCipher` whose key is stored in `flutter_secure_storage`.

---

### LOW — `storage.rules` duplicated unclosed match block (pre-existing)

**File:** `storage.rules` lines 30–41

Outer `/users/{uid}` block never closes before the inner block opens, effectively bypassing the content-type restriction. Pre-existing; not introduced by this PR.

---

### INFO — `intl: ^0.19.0` clean; no CVEs

Resolved to `0.19.0` (pubspec.lock verified). No CVEs. Usage limited to `DateFormat` on server-side timestamps.

### INFO — `beneficiaryId` not user-injectable

Confirmed sourced from `currentUser.uid` via `authStateProvider`; not from path/query params.

### INFO — `batchId.substring` safe

`.length.clamp(0, 8)` applied before `substring`; no `RangeError` possible.

### INFO — No new secrets introduced by this PR

All 17 new/modified Dart files scanned. No API keys, tokens, or credentials introduced.

---

## Secret Management Checklist

- [x] No API keys in new `.dart` files
- [x] `beneficiaryId` sourced from auth, not user input
- [ ] `firebase_options.dart` contains live Firebase API keys tracked in git — **FAIL** (pre-existing HIGH)
- [ ] `delivery_history_cache` Hive box not encrypted; `flutter_secure_storage` unused for this box — **FAIL**
- [ ] Hive cache not cleared on logout — **FAIL**
- [x] `.env` files gitignored
- [x] `google-services.json` and `GoogleService-Info.plist` gitignored

---

## Summary

CHANGES REQUESTED. Two blocking items before merge:

1. The Firestore `batches` read rule (`allow read: if isSignedIn()`) provides zero server-side ownership enforcement — any authenticated user can read any beneficiary's delivery history. Must be fixed in `firestore.rules`.
2. The open `batches` rule combined with the pre-existing exposed web Firebase API key in `firebase_options.dart` enables unauthenticated REST enumeration of personal delivery history.

Two MEDIUM findings (missing role guard, unencrypted/uncleared Hive cache) must be resolved before next release. The cursor hard cast is a low-risk fragility worth guarding.
