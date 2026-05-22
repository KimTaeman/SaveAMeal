---
Date: 2026-05-22 00:00
Member: Kim Taeman
Agent: architect
Task: Set up SaveAMeal project — branch, folder structure, Firebase scaffold, branch protection
Prompt: checkout to new branch. read SaveAMeal_Architecture (1).docx. set branch protection on main, project name is saveameal. set up shared folder structure per architecture. firebase setup.

Outcome: Scaffolded SaveAMeal project — branch setup/saveameal-init created; pubspec renamed to saveameal with 7 new packages added; 51 new files across features/donor, features/driver, features/beneficiary, features/auth, services/, core/models/, core/constants/; all package:mobile/ imports replaced with package:saveameal/; ADR 0005 written.
Decisions: Retained Riverpod over Provider (superset, already scaffolded, avoids mid-project migration) — documented in ADR 0005. Firebase chosen over Supabase per arch doc reasoning. Services layer is thin Firebase wrappers; feature datasources delegate to services.
Handoff: Run `flutterfire configure` to generate firebase_options.dart and update main.dart Firebase.initializeApp() call. Add Google Maps API keys to android/AndroidManifest.xml and ios/AppDelegate.swift. Set up Firestore security rules. Build runner not yet run — run `dart run build_runner build` once firebase_options.dart exists.
Review: PENDING
