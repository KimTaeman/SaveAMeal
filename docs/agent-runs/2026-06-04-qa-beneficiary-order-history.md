# QA Review — SPEC-0007 Beneficiary Order History
Date: 2026-06-04
Reviewer: qa-engineer
Branch: feat/beneficiary-order-history
Verdict: CHANGES REQUESTED

---

## Coverage Gaps

**FAIL — Missing: `_LoadMoreFooter` spinner state (isLoadingMore == true)**
The seven widget tests in `delivery_history_screen_test.dart` never set `isLoadingMore: true`. The `OutlinedButton.icon` branch that renders a `CircularProgressIndicator` (16×16, `strokeWidth: 2`) and disables `onPressed` is completely untested. A dedicated test should stub a `DeliveryHistoryState(items: [...], hasMore: true, isLoadingMore: true)` and assert that `onPressed` is null (button disabled) and the small progress indicator appears inside the footer.

**FAIL — Missing: `loadMoreError` inline error row**
No test exercises the `state.loadMoreError != null` branch in `_LoadMoreFooter`. This renders an `Icons.error_outline` row with a "Retry" `TextButton`. A regression in that branch would go undetected.

**FAIL — Missing: `OrderHistoryStatsBar` disclaimer when `hasMore == true`**
The widget test for the populated state (`renders list rows for populated state`) uses `hasMore: false`, so the `'*Showing totals for loaded deliveries'` disclaimer text is never asserted. Neither `delivery_history_screen_test.dart` nor a dedicated `order_history_stats_bar_test.dart` covers this branch.

**FAIL — Missing: network failure on first build with non-empty Hive cache**
`delivery_history_notifier_test.dart` covers the happy path and `hasMore: false` short-page path, but the cache-fallback branch in `build()` (lines 103–110 of `delivery_history_notifier.dart`) has no test. When the network throws and `cached.isNotEmpty`, the notifier should return cached items with `hasMore: true`. This branch is a critical offline-resilience path with zero test coverage.

**FAIL — Missing: network failure on first build with empty cache (rethrow)**
The counterpart branch — network throws AND cache is empty — is also untested. The notifier is expected to `rethrow`, which causes the provider to enter `AsyncError`. No unit test verifies this. Both cache-fallback paths together represent the primary resilience contract of the notifier.

**PASS — `items.isEmpty && hasMore == true` edge case**
`delivery_history_screen.dart` line 42 guards `if (state.items.isEmpty && !state.hasMore)` for the empty body. When `items=[]` and `hasMore=true`, the code falls through to the populated scaffold with an empty `SliverList.builder` and a `Load More History` footer. This edge case has no dedicated widget test but is a minor UX gap, not a functional defect — flagged as informational.

---

## Accessibility Issues

**HIGH — `_CategoryIcon` has no semantic label**
`delivery_history_row.dart` line 162–169: the 28×28 circular `Container` wrapping an `Icon` carries no `Semantics` widget and no `Tooltip`. It conveys the food category (meals / baked goods / produce / general) as meaningful information. Screen readers will announce the raw `Icon` semantics, which defaults to the icon name rather than the category. Fix: wrap in `Semantics(label: _categoryLabel(category), child: ...)` or `Tooltip(message: _categoryLabel(category), child: ...)`.

**HIGH — `_StatusChip` icon is redundant but text carries semantics fine; however badge lacks role**
The green pill in `delivery_history_row.dart` (lines 129–147) contains both an `Icon(Icons.check_circle_outline)` and `Text('Delivered')`. The text is readable by TalkBack/VoiceOver, so the chip itself is not silent. However, the check icon inside the chip has no `ExcludeSemantics` wrapper, meaning the screen reader will announce both the icon semantics and the text. Fix: wrap the inner `Icon(Icons.check_circle_outline, ...)` in `ExcludeSemantics`.

**HIGH — `_EmptyBody` decorative icon not excluded from semantics**
`delivery_history_screen.dart` line 237: `Icon(Icons.inbox_outlined, size: 72, ...)` is purely decorative — all meaning is conveyed by the adjacent `Text('Your delivery history will appear here')`. The icon is not wrapped in `ExcludeSemantics`, so TalkBack will announce it redundantly. Fix: wrap in `ExcludeSemantics(child: Icon(...))`.

**HIGH — `_ErrorBody` decorative icon not excluded from semantics**
`delivery_history_screen.dart` line 267: `Icon(Icons.cloud_off, size: 56, ...)` has the same issue. The adjacent text conveys the message. Fix: wrap in `ExcludeSemantics(child: Icon(...))`.

**HIGH — `OrderHistoryCard` category icon has no semantic label**
`order_history_card.dart` lines 68–82: the 36×36 circular container holding the food-category icon carries no `Semantics` label. Fix: same approach as `_CategoryIcon` above.

**HIGH — `OrderHistoryCard` status badge icons not excluded from semantics**
`_deliveredBadge` (line 150) and `_inTransitBadge` (line 173) each contain an inner `Icon` alongside `Text`. The text is readable; the icons are decorative in context. Fix: wrap each badge's `Icon(...)` in `ExcludeSemantics`.

**INFORMATIONAL — `DeliveryHistoryRow` `InkWell` lacks a semantic label**
The card is tappable via `InkWell.onTap` but has no `Semantics(label: 'View delivery $orderRef')` wrapper. TalkBack will announce the child text piecemeal rather than as a single coherent action. This does not block WCAG AA compliance (the content is readable) but degrades the screen-reader UX.

---

## Performance Notes

**LOW — `IntrinsicHeight` in `DeliveryHistoryRow`**
`delivery_history_row.dart` line 40: `IntrinsicHeight` forces a double-layout pass on every row rendered by `SliverList.builder`. For typical page sizes of 20 items this is acceptable, but it is an avoidable per-row cost. The same visual result (left accent border stretching full card height) is achievable with a `Row` + `crossAxisAlignment: CrossAxisAlignment.stretch` directly inside the `Card`, without `IntrinsicHeight`. Flagged as low-priority refactor.

**LOW — `IntrinsicHeight` in `OrderHistoryStatsBar`**
`order_history_stats_bar.dart` line 31: the two-tile stat row uses `IntrinsicHeight` to size the `VerticalDivider`. Same concern. Achieved alternatively with a fixed-height `SizedBox` for the divider.

**INFORMATIONAL — `OrderHistoryStatsBar.fold()` grows with loaded pages**
The `.fold(0, (sum, d) => sum + d.portions)` at line 19–21 runs on every `build()` call and iterates all loaded items. With 20 items per page and a typical session loading 2–3 pages this is negligible (<100 items). If the PR roadmap ever raises `kDeliveryHistoryPageSize` or users accumulate very large histories, this should be memoised (e.g., computed once in the notifier state). Informational only at current page size.

**PASS — No unbounded ListView**
`SliverList.builder` is used throughout `DeliveryHistoryScreen`. `BeneficiaryOrderHistoryScreen` uses `SliverChildBuilderDelegate`. Neither introduces an unbounded list. Passes the architectural convention.

---

## Edge Case Notes

**PASS — `batchId` shorter than 8 chars**
`delivery_history_row.dart` line 25: `batchId.length.clamp(0, 8)` guards `substring` against short IDs. Safe.

**PASS — `donorName == null`**
`delivery_history_row.dart` line 96: `delivery.donorName ?? "Unknown donor"` handles null. Safe.

**PASS — Empty or null `category`**
`_categoryLabel` returns `'Portions'` for null or empty category. `_iconAndColor` returns the default icon for null. Safe.

**INFO — `items.isEmpty && hasMore == true` state**
Produces an empty `SliverList.builder` plus a `Load More History` button with no list rows — a valid but visually odd state (stats bar shows "0 meals / 0 deliveries" with a "Load More" button below). No test covers this; a brief comment in the screen file would clarify intent.

**INFO — `recent_deliveries_section.dart` `TextButton` padding**
The `TextButton.styleFrom(padding: EdgeInsets.zero)` was removed during the merge fix. The "View All" button now renders with default Flutter padding (~8dp horizontal). This is a cosmetic regression from the Figma design (low priority) and does not affect correctness.

---

## Summary

The feature is structurally sound: Clean Architecture layering is respected, `SliverList.builder` is used correctly, Hive caching and pagination guards are implemented, and the 10 existing tests all cover meaningful states. However, the PR must not merge in its current form due to five coverage gaps and six accessibility defects.

The two most critical items are (1) the absence of unit tests for both Hive cache-fallback branches in `DeliveryHistoryNotifier.build()` — the primary resilience contract of the feature — and (2) four decorative icons (`_EmptyBody`, `_ErrorBody`, `_CategoryIcon` in `DeliveryHistoryRow`, category icon in `OrderHistoryCard`) that are not wrapped in `ExcludeSemantics` or given semantic labels, which will produce confusing or redundant announcements under TalkBack/VoiceOver. The `_LoadMoreFooter` spinner and `loadMoreError` row are also untested. All blocking items are straightforward to fix and should not require design changes.
