# SaveAMeal — Mobile App

  > "Every meal counts. Every minute matters."

  A cross-platform Flutter app (Android, iOS, Web) that connects commercial food donors, crowdsourced volunteer drivers, and
  community beneficiaries into a real-time food rescue network.

  ## Quick start

  ### Prerequisites

  - Flutter SDK (see `.fvm/fvm_config.json` for pinned version)
  - Firebase config files (see **Firebase setup** below)

  ### Firebase setup

  These files are gitignored. Download from [console.firebase.google.com](https://console.firebase.google.com) → project
  **saveameal-87187** → Project settings → Your apps:

  | File | Destination |
  |------|------------|
  | `google-services.json` | `apps/mobile/android/app/` |
  | `GoogleService-Info.plist` | `apps/mobile/ios/Runner/` |

  > Web (`flutter run -d chrome`) works without either file — start here for fast dev iteration.

  ### Install and generate code

  ```bash
  cd apps/mobile
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs

  Run

  cd apps/mobile
  flutter run -d chrome       # web — no Firebase config needed
  flutter run                 # connected Android/iOS device

  Test and lint

  cd apps/mobile
  flutter test                              # all unit + widget tests
  flutter analyze                           # must pass with zero errors
  dart format . --set-exit-if-changed       # formatting check

  Architecture

  Clean Architecture — Domain layer is pure Dart with zero Flutter or Firebase imports.

  lib/
    features/
      auth/         ← login, register, role routing
      donor/        ← log surplus, QR display, dashboard
      driver/       ← map, job claim, pickup, delivery
      beneficiary/  ← status toggle, live tracking, confirm receipt
    shared/         ← design system, widgets, theme tokens
    core/           ← logging, constants, models
    shared/         ← design system, widgets, theme tokens
    core/           ← logging, constants, models
    services/       ← Firebase service wrappers (Auth, Firestore, Storage, FCM)

  See CLAUDE.md (../../CLAUDE.md) for the full stack table and conventions.

  Seed data

  Populate Firestore with realistic test data (10 users, 4 beneficiaries, 12 batches):

  # Against the emulator (recommended)
  firebase emulators:start --only firestore
  cd tools/seed && npm install && node seed.js --emulator

  # Wipe and re-seed
  node seed.js --emulator --clean

  Contributing

  See CONTRIBUTING.md (../../CONTRIBUTING.md) for the branching, commit style, and agent-logging rules.
