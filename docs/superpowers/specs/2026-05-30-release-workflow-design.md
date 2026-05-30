# Release Workflow Design

**Date:** 2026-05-30
**Status:** Approved
**Author:** KimTaeman

## Goal

Automate building a debug Android APK and publishing it as a GitHub Release asset whenever a version tag is pushed. Lets the team sideload the APK directly from GitHub to test QR scanning and user flows.

## Trigger

```yaml
on:
  push:
    tags:
      - 'v*'
```

Fires on any tag matching `v*` (e.g., `v1.0.1`, `v1.1.0`). Does not run on branch pushes — that is handled by the existing `ci.yml`.

## Permissions

```yaml
permissions:
  contents: write
```

Required to create a GitHub Release and upload assets. Satisfied by the built-in `GITHUB_TOKEN` — no additional secrets needed beyond what `ci.yml` already uses.

## Workflow File

**Path:** `.github/workflows/release.yml`

## Jobs

Single job: `release`, running on `ubuntu-latest`.

### Steps

| # | Step | Detail |
|---|------|--------|
| 1 | Checkout | `actions/checkout@v4` |
| 2 | Setup Java | `actions/setup-java@v4`, Temurin distribution, Java 17 |
| 3 | Setup Flutter | `subosito/flutter-action@v2`, stable channel, cache enabled |
| 4 | Install dependencies | `flutter pub get` |
| 5 | Code generation | `dart run build_runner build --delete-conflicting-outputs` |
| 6 | Write google-services.json | Decode `GOOGLE_SERVICES_JSON` secret (base64); falls back to CI placeholder if absent — same logic as `ci.yml` |
| 7 | Build APK | `flutter build apk --debug` |
| 8 | Create GitHub Release | `softprops/action-gh-release@v2` — attaches APK renamed to `saveameal-<tag>.apk`, auto-generates changelog from commits since previous tag |

### APK output path

```
apps/mobile/build/app/outputs/flutter-apk/app-debug.apk
```

### Asset naming

The APK is renamed before upload:

```
saveameal-v1.0.1.apk
```

This makes it unambiguous to identify which build belongs to which release in the GitHub Assets list.

## Secrets

| Secret | Required | Purpose |
|--------|----------|---------|
| `GOOGLE_SERVICES_JSON` | Optional | Base64-encoded `google-services.json` for Firebase. Already configured in repo. Falls back to CI placeholder if absent. |
| `GITHUB_TOKEN` | Automatic | Built-in; no setup needed. Used to create the release and upload the asset. |

## Usage

```bash
# Bump version in pubspec.yaml first (e.g., 1.0.0+1 → 1.0.1+2), then:
git add apps/mobile/pubspec.yaml
git commit -m "chore: bump version to 1.0.1"
git tag v1.0.1
git push origin main --tags

# ~5 minutes later: GitHub Release appears at:
# https://github.com/KimTaeman/SaveAMeal/releases/tag/v1.0.1
# Download saveameal-v1.0.1.apk → enable "Install from unknown sources" → install
```

## What this does NOT cover

- iOS build (requires macOS runner and Apple signing)
- Release-signed APK (requires Android keystore setup)
- Play Store upload (requires service account)

These can be added in future iterations if needed.
