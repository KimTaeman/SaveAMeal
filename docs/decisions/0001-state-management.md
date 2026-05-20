---
title: "0001: Use Riverpod 2.x with code generation for state management"
description: "Riverpod 2.x chosen over BLoC and Provider for compile-time safety and Clean Architecture compatibility."
---

# 0001 — State Management: Riverpod 2.x

**Status:** ACCEPTED
**Author:** architect
**Date:** 2026-05-19

## Problem

The app requires a state management solution that enforces the Clean Architecture boundary between the Domain and Presentation layers, provides compile-time provider safety, supports code generation to reduce boilerplate, and is testable without requiring a `BuildContext`. The solution must work on Android, iOS, and Web.

## Options Considered

| # | Option | Upside | Downside |
|---|--------|--------|----------|
| 1 | Riverpod 2.x + riverpod_generator | Compile-time safety; no `BuildContext` dependency; auto-disposal; code-gen; `ProviderScope` override in tests | Learning curve for teams used to Provider |
| 2 | BLoC / flutter_bloc | Mature; explicit event/state model; good for complex multi-step flows | Boilerplate-heavy; no compile-time provider safety; harder to scope providers |
| 3 | Provider | Simple; widely documented | Effectively superseded by Riverpod; runtime `ProviderNotFoundException` on misuse |

## Decision

**Chosen:** Option 1 — Riverpod 2.x with riverpod_generator

Riverpod 2.x eliminates runtime `ProviderNotFoundException` errors through compile-time analysis, auto-disposes providers when their last listener unsubscribes, and generates type-safe provider classes via `@riverpod` annotations. It separates provider reads from `BuildContext` entirely, which satisfies the Clean Architecture requirement: Presentation providers can depend on Domain use cases without importing any widget or framework class.

## Reversal Cost

Medium — migrating from Riverpod to BLoC requires rewriting all `presentation/providers/` files. Domain and Data layers are unaffected as they have no Riverpod imports.

## Consequences

- All stateful presentation logic lives in `features/<name>/presentation/providers/` using `@riverpod`
- `build_runner` must be re-run after every provider change: `dart run build_runner build`
- Test overrides use `ProviderScope(overrides: [myProvider.overrideWith(...)])`
- Domain use cases are injected as provider family parameters — no BuildContext in domain
