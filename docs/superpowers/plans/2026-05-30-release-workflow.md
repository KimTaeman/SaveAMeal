# Release Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `.github/workflows/release.yml` so that pushing a `v*` tag builds a debug APK and publishes it as a downloadable GitHub Release asset.

**Architecture:** A single GitHub Actions workflow file triggered on `v*` tag pushes. It reuses the same build steps as the existing `ci.yml` `build-android` job, renames the output APK to include the tag name, then uses `softprops/action-gh-release@v2` to create the GitHub Release and upload the APK. No application code changes.

**Tech Stack:** GitHub Actions, `subosito/flutter-action@v2`, `softprops/action-gh-release@v2`, Flutter (stable), Java 17 (Temurin)

---

## File Map

| Action | Path | Responsibility |
|--------|------|---------------|
| Create | `.github/workflows/release.yml` | Full release pipeline — build APK, create GitHub Release, upload asset |

---

### Task 1: Create the release workflow file

**Files:**
- Create: `.github/workflows/release.yml`

- [ ] **Step 1: Create the workflow file with the following exact content**

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

defaults:
  run:
    working-directory: apps/mobile

jobs:
  release:
    name: Build & Release APK
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Write google-services.json
        run: |
          TARGET=android/app/google-services.json
          if [ -n "$GOOGLE_SERVICES_JSON_B64" ]; then
            echo "$GOOGLE_SERVICES_JSON_B64" | base64 --decode > "$TARGET"
          else
            cat > "$TARGET" << 'GSJSON'
          {"project_info":{"project_number":"000000000000","project_id":"saveameal-ci","storage_bucket":"saveameal-ci.appspot.com"},"client":[{"client_info":{"mobilesdk_app_id":"1:000000000000:android:0000000000000000000000","android_client_info":{"package_name":"com.example.mobile"}},"oauth_client":[],"api_key":[{"current_key":"ci-placeholder"}],"services":{"appinvite_service":{"other_platform_oauth_client":[]}}}],"configuration_version":"1"}
          GSJSON
          fi
        env:
          GOOGLE_SERVICES_JSON_B64: ${{ secrets.GOOGLE_SERVICES_JSON }}

      - name: Build Android APK (debug)
        run: flutter build apk --debug

      - name: Rename APK
        run: |
          mkdir -p release-artifacts
          cp build/app/outputs/flutter-apk/app-debug.apk \
             release-artifacts/saveameal-${{ github.ref_name }}.apk

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
          files: apps/mobile/release-artifacts/saveameal-${{ github.ref_name }}.apk
```

- [ ] **Step 2: Validate the YAML structure**

Run in PowerShell from the repo root:

```powershell
Get-Content .github\workflows\release.yml | Select-String "^\s*-\s+uses:" | ForEach-Object { $_.Line.Trim() }
```

Expected output (4 action references, in order):
```
- uses: actions/checkout@v4
- uses: actions/setup-java@v4
- uses: subosito/flutter-action@v2
- uses: softprops/action-gh-release@v2
```

If the output is missing any of those lines, check the YAML indentation in the file.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: add release workflow to publish debug APK on version tag"
```

---

### Task 2: Push a test tag and verify the release

- [ ] **Step 1: Push the commit to main**

```bash
git push origin main
```

- [ ] **Step 2: Create and push a version tag**

```bash
git tag v1.0.1
git push origin v1.0.1
```

- [ ] **Step 3: Watch the workflow run**

Go to `https://github.com/KimTaeman/SaveAMeal/actions` and open the **Release** workflow run that just appeared. It should show the single `Build & Release APK` job progressing through each step. Build takes ~5 minutes.

- [ ] **Step 4: Verify the GitHub Release**

Once the workflow completes (green checkmark), go to `https://github.com/KimTaeman/SaveAMeal/releases`. You should see:

- A release titled **v1.0.1**
- An auto-generated changelog under "What's Changed"
- An asset named **`saveameal-v1.0.1.apk`** with a download link

- [ ] **Step 5: Sideload the APK on your phone**

1. Download `saveameal-v1.0.1.apk` from the release page (or scan the direct download link as a QR code)
2. On your Android phone: Settings → Apps → Special app access → Install unknown apps → allow your browser
3. Open the downloaded APK and tap Install
4. Launch SaveAMeal and run through your QR scan and user flow tests

---

### Task 3: Clean up test tag (optional)

If `v1.0.1` was only a test and you want to remove it from Releases:

- [ ] **Step 1: Delete the tag locally and remotely**

```bash
git tag -d v1.0.1
git push origin --delete v1.0.1
```

- [ ] **Step 2: Delete the GitHub Release**

Go to `https://github.com/KimTaeman/SaveAMeal/releases/tag/v1.0.1`, click **Edit**, then **Delete this release**. This removes the release page but does not affect commits.
