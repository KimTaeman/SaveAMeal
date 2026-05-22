# Contributing

## Workflow

All work follows the agent-driven planning workflow defined in `CLAUDE.md` and detailed in `docs/workflow.md`. Before writing any code:

1. **Architect** designs the layer structure and data schema
2. Plan is presented and approved
3. **Flutter Engineer** implements the approved plan
4. **Architect or QA Engineer** reviews — never the same agent that wrote the code

For tasks spanning more than 2 files or touching architecture, use Plan Mode first.

## Branching

```
main              ← stable, always green
feat/<name>       ← feature branches (from main)
fix/<name>        ← bug fixes
chore/<name>      ← tooling, deps, CI
```

Branch from `main`. Open a PR back to `main`. Squash-merge on approval.

## Commit style

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add theme switcher screen
fix: prevent crash when Hive box not open
refactor: remove duplicate border token from AppColors
test: add widget test for ProfileScreen
chore: upgrade flutter to 3.24
docs: add ADR for state management choice
```

## First-time setup

### 1. Clone and install hooks

```bash
git clone git@github.com:KimTaeman/new-flutter-app.git
cd new-flutter-app
sh tools/setup.sh   # installs pre-commit hook, runs pub get + codegen
```

### 2. Get Firebase config files (required — do not skip)

These files are gitignored (they are tied to our Firebase project). Download them from the Firebase console:

1. Open [console.firebase.google.com](https://console.firebase.google.com) → select project **saveameal-87187**
2. Click the **⚙️ gear icon** (top-left) → **Project settings**
3. Scroll down to **"Your apps"**

**Android** — `google-services.json`
- Click the Android app entry → **Download google-services.json**
- Place the file at: `apps/mobile/android/app/google-services.json`

**iOS** — `GoogleService-Info.plist`
- Click the iOS app entry → **Download GoogleService-Info.plist**
- Place the file at: `apps/mobile/ios/Runner/GoogleService-Info.plist`

> Without these files the app will crash on launch with a Firebase initialization error.

### 3. Run code generation

Generated files (`*.g.dart`, `*.freezed.dart`) are also gitignored. Regenerate them:

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run the app

```bash
cd apps/mobile

flutter run -d chrome          # Web (fastest for dev — no Firebase config needed for web)
flutter run                    # Connected Android/iOS device
flutter run -d <device-id>     # Specific device (see: flutter devices)
```

### 5. Verify everything works

```bash
cd apps/mobile
flutter analyze                # Must pass with zero errors
flutter test                   # Run all unit + widget tests
dart format . --set-exit-if-changed   # Check formatting
```

## Running the app

All Flutter commands run from `apps/mobile/`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
flutter test
flutter analyze
dart format .
```

## Architecture rules

- **Domain layer**: zero Flutter or backend imports — pure Dart only
- No unbounded `ListView` — always `ListView.builder` or `SliverList`
- All remote images through `CachedNetworkImage`
- No plaintext secrets — use `--dart-define` or remote config
- Every screen must have a widget test

## Code generation

Never edit `*.g.dart` or `*.freezed.dart` files directly. Regenerate with:

```bash
dart run build_runner build
```

## PR checklist

See `.github/PULL_REQUEST_TEMPLATE.md` — the checklist is enforced on every PR.

## Agent logging

Every session must be logged in `docs/agent-log-<member>.md` per the format in `CLAUDE.md`. The agent that writes code must not be the agent listed under `Review: APPROVED`.
