# 0016 — Confirm Receipt: beneficiaryId resolution strategy

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-06-04

## Problem

`ConfirmReceiptUseCase` needs a `beneficiaryId` to pass to `IntakeRepository.confirmReceipt` for logging and tracing. Two candidate sources exist: the auth session (via `authStateProvider`) or the already-loaded `IntakeRequestDetail.beneficiaryId` which is available in `DeliveryDetailScreen`. The choice determines whether `AuthRepository` leaks into the domain layer and whether the presentation layer passes identity state as constructor arguments to screens.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | `ConfirmReceiptNotifier` reads `uid` from `authStateProvider` and passes it as a parameter to `ConfirmReceiptUseCase.call` | Use case stays pure Dart with no cross-feature dependency; single authoritative identity source; no risk of stale or spoofed beneficiaryId from a loaded entity | Presentation layer is responsible for auth plumbing one level above the use case |
| 2 | Inject `AuthRepository` into `ConfirmReceiptUseCase` | Use case is self-contained and resolves its own identity | Introduces a cross-feature domain dependency (`auth` → `beneficiary` domain) and requires `AuthRepository` to be a pure-Dart interface, which it already is — but still couples domain layers |
| 3 | Pass `beneficiaryId` from `DeliveryDetailScreen` via `extra` or constructor to `ConfirmReceiptScreen` | No auth-layer access needed anywhere in the confirm-receipt feature | `beneficiaryId` originates from a Firestore document, not the authoritative auth session; a mismatch between session uid and loaded entity uid is possible if the stream emits stale data |

## Decision

**Chosen: Option 1 — notifier reads `uid` from `authStateProvider`, passes it as a parameter.**

The use case remains a pure Dart class with a single `IntakeRepository` dependency, satisfying the zero-framework-import domain constraint. The `ConfirmReceiptNotifier` is already a Riverpod notifier with access to `ref`; reading `authStateProvider` there is idiomatic and does not require any new abstraction. Using the auth session as the identity source is more secure than trusting a field from a loaded document, which could theoretically differ from the authenticated user in edge cases.

## Reversal Cost

Low. If the team later decides to inject `AuthRepository` directly into the use case, the change is confined to `confirm_receipt_usecase.dart`, `confirm_receipt_provider.dart`, and their tests — approximately 3 files with no impact on domain interfaces or data layer implementations.

## Consequences

**Easier:** Domain layer stays free of cross-feature imports. Use case is trivially unit-testable with a single mock (`IntakeRepository`). Identity is always the live session uid, not a value from a potentially-stale Firestore document.

**Harder:** The notifier must handle the case where `authStateProvider` returns `null` (unauthenticated), setting an error state rather than calling the use case. This edge case must be covered by tests.
