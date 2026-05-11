## Summary

<!-- What does this PR do? Link the tech spec if applicable. -->

**Spec:** tech-specs/NNNN-slug.md  
**Branch type:** `feat` / `fix` / `chore` / `docs`

---

## Implementation checklist

- [ ] Domain entities have zero Flutter or backend imports
- [ ] Repository interfaces defined in `domain/repositories/`
- [ ] Data source implemented in `data/datasources/`
- [ ] Freezed models with `fromJson`/`toJson` in `data/models/`
- [ ] Use cases in `domain/usecases/` — one class, one public method each
- [ ] Riverpod providers use `@riverpod` code gen
- [ ] Screens registered in GoRouter
- [ ] Widget test for every new screen
- [ ] No new unbounded `ListView` (use `ListView.builder` or `SliverList`)
- [ ] Remote images use `CachedNetworkImage`
- [ ] No hardcoded colors, text styles, or spacing values
- [ ] No plaintext secrets in Dart source

## Quality checklist

- [ ] `flutter analyze` passes with zero issues
- [ ] `dart format .` shows no diff
- [ ] All tests pass (`flutter test`)
- [ ] Code gen up to date (`dart run build_runner build`)

## Review

<!-- The engineer who wrote this code must NOT be the reviewer. -->

- [ ] Reviewed by: `architect` / `qa-engineer` / `security-reviewer`
- [ ] Report written to `docs/agent-runs/`
- [ ] Session log updated in `docs/agent-log-<member>.md`
