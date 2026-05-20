---
name: feature-flag
description: >-
  Scaffold a remote feature flag: defines the flag constant, creates a Riverpod
  provider reading from Firebase Remote Config, gates the feature in the relevant
  widget, and stubs a rollback test. Use when adding a feature flag, gating a
  feature behind a kill switch, or implementing a staged rollout.
---

# Feature Flag Skill

## When to use

Any time a feature needs to be gated behind a remote toggle with a documented
rollback plan (required by assignment R4).

## Steps

### 1. Define the flag constant

Add to `lib/core/feature_flags/feature_flags.dart`:

```dart
abstract final class FeatureFlags {
  static const String kMyFeature = 'my_feature_enabled';
}
```

### 2. Create the Riverpod provider

Create `lib/core/feature_flags/feature_flag_provider.dart`:

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feature_flag_provider.g.dart';

@riverpod
bool featureFlag(FeatureFlagRef ref, String key) {
  return FirebaseRemoteConfig.instance.getBool(key);
}
```

Default must be `false` — off by default ensures safe rollout.

### 3. Gate the feature in the widget

```dart
final enabled = ref.watch(featureFlagProvider(FeatureFlags.kMyFeature));
if (enabled) {
  // @Experimental — gated by kMyFeature remote config flag
  return const MyFeatureWidget();
}
return const SizedBox.shrink();
```

### 4. Set defaults in Firebase Remote Config console

- Key: `my_feature_enabled`
- Default value: `false`
- Add a description entry to `docs/feature-flags.md`

### 5. Write rollback tests

In `test/core/feature_flags/feature_flag_test.dart`:

```dart
// Flag false → feature is hidden
// Flag true  → feature is visible
```

Override the provider in `ProviderScope(overrides: [...])`.

### 6. Document the rollback plan

In the PR description and release notes:

> **Rollback:** Set `my_feature_enabled = false` in Firebase Remote Config console.
> Effect: feature hidden for all users within the Remote Config fetch interval (~1 hour).

## Rollback invariants (enforced by release-engineer)

- [ ] Flag defaults to `false`
- [ ] Test exists verifying the app is functional with the flag off
- [ ] Rollback command documented in release notes
