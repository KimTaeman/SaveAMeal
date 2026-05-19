---
title: "0003: Use Hive for offline-first local data caching"
description: "Hive chosen over Drift for document-oriented offline caching that mirrors Firestore's data model."
---

# 0003 — Offline Storage: Hive

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-05-19

## Problem

The app requires an offline-first caching strategy for critical Firestore data so that the app degrades gracefully on flaky or absent network connections. The solution must work identically on Android, iOS, and Web (assignment R2, R4).

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Hive + hive_flutter | Document-oriented boxes mirror Firestore collections; works on Web via IndexedDB; fast reads; lightweight | No relational queries; no native schema migrations |
| 2 | Drift (SQLite ORM) | Type-safe SQL queries; first-class migrations; DAOs align well with repositories | SQLite does not run on Web without `drift_flutter` web shim; relational schema mismatch with Firestore documents |
| 3 | SharedPreferences | Zero setup | Not designed for structured data; no querying capability |

## Decision

**Chosen:** Option 1 — Hive

Hive's box-per-collection model maps directly to Firestore's collection/document structure, making cache hydration straightforward: one `TypeAdapter` per Freezed model, one box per collection. All three target platforms (Android, iOS, Web) are supported without platform-specific configuration; on Web, `hive_flutter` uses IndexedDB transparently. Hive type adapters can be generated alongside Freezed models in a single `build_runner` pass.

## Reversal Cost

Medium — the Data layer's repository implementations would need to be rewritten to use Drift. Domain entities and use cases remain unchanged because repositories are accessed only through their abstract interfaces.

## Consequences

- Each Firestore collection has a corresponding `HiveBox<T>` in the local cache
- Hive `TypeAdapter`s are generated in `data/models/*.g.dart` via `build_runner`
- Cache strategy: read from Hive first, sync from Firestore in background, write back to Hive on success
- Box names are constants in `lib/core/storage/hive_boxes.dart`
- Web platform: `Hive.initFlutter()` uses IndexedDB (no extra config needed)
