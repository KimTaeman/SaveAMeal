---
date: 2026-06-05
agent: security-reviewer
branch: feat/beneficiary-batches
pr-commits: c3763a3, 423ffec, 2090685
verdict: CHANGES REQUESTED
---

# Security Review — feat/beneficiary-batches

## Executive Summary

This PR introduces a `DriverInfoCard` UI fix, `estimatedArrivalMinutes` / `beneficiaryLat` / `beneficiaryLng` schema fields, and a real-time ETA streaming loop that writes every 30 seconds from the driver client. The Dart-side code is structurally sound: no plaintext secrets introduced, ETA calculation is pure math with good test coverage, and the TOCTOU guard in `_writeEtaIfChanged` is correctly implemented. Two issues require attention before production.

---

## Findings

### H-1 — No field-level Firestore rule for `estimatedArrivalMinutes` writes (CWE-284)

**Severity:** HIGH — fix before merge

**File:** `apps/mobile/lib/services/firestore_service.dart` (lines 319–322); `firestore.rules` (driver-update arm)

The broad driver-update rule allows writing **any** field to a claimed batch:

```
isDriver() && resource.data.driverId == uid()
  && resource.data.status in ['claimed', 'pickedUp']
```

This means a malicious driver can overwrite `beneficiaryId`, `donorId`, `items`, or other immutable fields using the Firestore REST API. The 30-second ETA write loop makes this attack surface newly visible and regularly exercised.

**Required fix (rules only, no Dart change):**

```
isDriver() && resource.data.driverId == uid()
  && resource.data.status in ['claimed', 'pickedUp']
  && request.resource.data.diff(resource.data).affectedKeys()
       .hasOnly(['status', 'pickedUpAt', 'deliveredAt', 'deliveryNotes',
                 'pickupPhotoUrl', 'estimatedArrivalMinutes', 'updatedAt'])
```

---

### H-2 — `estimatedArrivalMinutes` written without server-side range validation (CWE-20)

**Severity:** HIGH — fix alongside H-1

**File:** `apps/mobile/lib/services/firestore_service.dart` (lines 319–322)

Any integer is accepted with no bounds check. A REST API caller can write negative values or `2,147,483,647`, which the beneficiary UI renders unclamped.

**Required fix:**
1. In the Security Rule: add `&& request.resource.data.estimatedArrivalMinutes is int && request.resource.data.estimatedArrivalMinutes >= 1 && request.resource.data.estimatedArrivalMinutes <= 600`
2. In `DriverInfoCard`: clamp displayed value (`detail.estimatedArrivalMinutes?.clamp(1, 600)`) as a client-side guard.

---

### H-3 — TOCTOU window in `claimBatch`: `autoId` lookup outside transaction (CWE-367)

**Severity:** HIGH — track as backlog item; does not block merge

**File:** `apps/mobile/lib/services/firestore_service.dart` (lines 273–316)

`findAvailableBeneficiaryId()` is called outside the transaction (Firestore limitation). Between the query and the transaction commit, the beneficiary may toggle to `paused` or two drivers can receive the same beneficiary ID. This PR does not introduce this race — it exists on `main` — but now the race also causes wrong delivery coordinates to be denormalised onto the batch.

**Recommendation:** Track a Cloud Function migration that assigns beneficiary + reads coords atomically server-side. As an interim, add a comment acknowledging the known gap.

---

## Informational

- **No secrets in diff.** No API keys, tokens, or credentials were introduced.
- **Firebase API key in `firebase_options.dart`** — pre-existing HIGH from 2026-06-04 review; not introduced by this PR.
- **`beneficiaryLat`/`beneficiaryLng` exposure to driver** — already readable by drivers (broad `allow read: if isSignedIn()` rule on `beneficiaries`). Denormalisation adds no new exposure.
- **`etaMinutes()` is mathematically correct** — Haversine handles all edge cases, minimum-1-minute floor, ceiling-rounded, 6 unit tests.
- **`_writeEtaIfChanged` local-capture pattern is correct** — TOCTOU guard between null-check and async write is well-implemented.
- **`unawaited(_writeEtaIfChanged(...))` is intentional** — ETA write failure is non-critical; timer retries in 30 s.
- **Bangkok fallback `LatLng(13.7563, 100.5018)`** — shows city centre, not beneficiary's actual location. Safe.

---

## Verdict: CHANGES REQUESTED

Block on H-1 + H-2 (Firestore Security Rule field allowlist + ETA range validation — rules-only fix). H-3 does not block merge but must be tracked as a High-priority backlog item.
