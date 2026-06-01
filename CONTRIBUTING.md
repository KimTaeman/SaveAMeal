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

These files are gitignored (tied to our Firebase project). Download them from the Firebase console:

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
> Web (`flutter run -d chrome`) works without them — start there if you don't need native.

### 3. Run code generation

Generated files (`*.g.dart`, `*.freezed.dart`) are gitignored. Regenerate them:

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run the app

```bash
cd apps/mobile

flutter run -d chrome          # Web — fastest for dev, no Firebase config needed
flutter run                    # Connected Android/iOS device
flutter run -d <device-id>     # Specific device — see: flutter devices
```

### 5. Verify everything works

```bash
cd apps/mobile
flutter analyze                       # Must pass with zero errors
flutter test                          # Run all unit + widget tests
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

## Local development data

### Seeding Firestore

The seed script populates Firestore with realistic Thai food rescue data (10 users, 4 beneficiaries, 12 batches across all statuses, 6 impact metric records).

**Against the emulator (recommended for dev):**

```bash
# Start the emulator first (from repo root)
firebase emulators:start --only firestore

# Then seed (from tools/seed/)
cd tools/seed
npm install          # first time only
node seed.js --emulator           # merge into existing data
node seed.js --emulator --clean   # wipe and re-seed (fresh state)
```

**Against live Firestore (requires a service account key):**

```bash
# 1. Download a service account key from:
#    console.firebase.google.com → saveameal-87187 → Settings → Service accounts → Generate new private key
# 2. Save as tools/seed/serviceAccountKey.json (gitignored — never commit it)

cd tools/seed
node seed.js --key serviceAccountKey.json --clean
```

**Register your own Firebase Auth UID as a donor or driver** (without wiping existing data):

```bash
node seed.js --emulator --add-driver <your-uid>
node seed.js --emulator --add-donor  <your-uid>
```

---

### Test scan codes (`docs/test-qr/index.html`)

A self-contained HTML page for testing barcode and QR scanning on a real device. Open it on a laptop, then use your phone running the app to scan.

**How to use:**

1. Open `docs/test-qr/index.html` in a desktop browser (Chrome/Edge)
2. Run the app on your phone and navigate to the role you want to test

**Section A — Donor (Log Surplus flow):**
- In the app: Donor → Log Surplus → tap the camera icon
- Scan any of the 6 EAN-13 barcodes (Mama noodles, Lay's, Oishi tea, Pocky, Milo, Bear Brand)
- The scanned barcode prefills the item form

**Section B — Driver (Verify Pickup flow):**
- In the app: Driver → claim a batch (e.g. `batch_004` or `batch_008`)
- Navigate to Verify Pickup
- Scan the matching QR code from Section B — the batch ID must match the one you claimed

> The QR codes encode plain batch IDs (e.g. `batch_004`). If the scanner shows "Wrong QR code", make sure you claimed that specific batch first.

---

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
