---
title: "0007: Intake Status Real-Time Strategy — Firestore Listener over Polling or Cloud Functions"
description: "Firestore snapshots() chosen as the delivery mechanism for intake status updates, with Security Rules as the RBAC enforcement point."
---

# 0007 — Intake Status Real-Time Strategy

**Status:** PROPOSED
**Author:** architect
**Date:** 2026-05-25

## Problem

The beneficiary-intake-status feature (PROP-0004) requires real-time status delivery and role-gated visibility in a three-sided automated marketplace (Donor → Volunteer → Beneficiary) with no manual staff intermediary. Status transitions are triggered automatically by Volunteer in-app actions (job acceptance, QR delivery scan). Three implementation strategies were evaluated: native Firestore real-time listener, HTTP polling, and a Cloud Functions write path fronting a Firestore listener. The team needed to pick one before the Flutter engineer begins implementation.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Firestore real-time listener + Security Rules | Real-time native to SDK; no new infrastructure; additive schema change; aligns with ADR-0004 | State machine rules enforced client-side or in Rules DSL, not authoritative server code |
| 2 | HTTP polling + REST endpoint | Server-enforced state machine and RBAC | Does not satisfy real-time constraint; requires new server infrastructure; higher battery cost |
| 3 | Cloud Functions write path + Firestore listener | Server-enforced state machine; still real-time on read | New dependency (functions workspace, Node runtime, CI deploy step); cold-start latency; disproportionate complexity for a five-state machine |

## Decision

**Chosen:** Option 1 — Firestore real-time listener + Firestore Security Rules

Firestore `snapshots()` is the only option that satisfies the real-time hard constraint without polling latency or battery penalty; it requires no infrastructure beyond what ADR-0004 already commits to. The state machine is small (four states, four legal transitions), the Volunteer role is a registered trusted actor, and Firestore Security Rules can encode the legal-transition guards explicitly (`allow write if resource.data.status == 'pending'` for accept; `'dispatched'` for delivery scan) — making server-enforced logic (Option 3) a disproportionate investment at this stage. If the state machine grows materially in complexity, migrating the write path to Cloud Functions is an incremental, bounded change that leaves the Domain layer and read path entirely intact.

## Reversal Cost

Medium — the read path (Firestore listener → `StreamProvider`) is identical under Options 1 and 3, so the beneficiary UI and Domain layer are unaffected by a later move to Cloud Functions. The write path in `FirestoreIntakeRepository` would be replaced by a callable function client, which is a Data-layer-only change. Migrating from Option 1 to Option 2 (polling) would be High cost because the entire real-time model would need to be replaced and the Domain interface contract would change.

## Consequences

- `IntakeRepository` in the Domain layer exposes `Stream<IntakeRequest>` — the real-time contract is part of the interface, not an implementation detail.
- Firestore Security Rules for the `intakes` collection become a mandatory review gate (same as all other collections per ADR-0004).
- Cloud Functions remain out of scope for this feature; if a security review later finds that client-writable status transitions are unacceptable, PROP-0004 will be superseded by a proposal that adds the Cloud Functions write path.
- The `FirestoreIntakeRepository` (Data layer) is the only file that imports `cloud_firestore` for this feature — Domain and Presentation layers remain framework-free.
