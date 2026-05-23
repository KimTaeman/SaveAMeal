---
title: "0001: Auth Flow"
description: "Full layer implementation of email/password auth with Firestore user docs and GoRouter redirect guard."
---

# SPEC-0001: Auth Flow

**Status:** APPROVED  
**Author:** KimTaeman  
**Date:** 2026-05-22  
**Proposal:** [PROP-0001](../tech-proposals/0001-auth-flow.md)  
**Approved by:** KimTaeman

---

## Overview

Implements sign-in, registration, and role-based routing for SaveAMeal. Firebase Auth provides the identity credential. Firestore stores the extended user profile (name, role). A GoRouter redirect guard enforces authentication for all protected routes. The domain layer remains pure Dart — no Firebase or Flutter imports.

## Architecture

```
Presentation              Domain                  Data
────────────              ──────                  ────
LoginScreen      ──────▶  SignInUsecase  ──────▶  AuthRepositoryImpl
RegisterScreen   ──────▶  SignUpUsecase           AuthRemoteDatasourceImpl
RoleRouterScreen ──────▶  SignOutUsecase           AuthService (Firebase Auth)
authStateProvider ◀─────  AuthRepository           FirestoreService (Firestore)
routerProvider            AppUser entity
                          UserRole enum
```

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `lib/services/auth_service.dart` | Wire up `FirebaseAuth.instance` |
| Modify | `lib/services/firestore_service.dart` | Implement `createUser` / `getUser` |
| Create | `lib/services/service_providers.dart` | `@riverpod` providers for services |
| Modify | `lib/features/auth/domain/repositories/auth_repository.dart` | Define full contract |
| Modify | `lib/features/auth/domain/usecases/sign_in_usecase.dart` | Implement `call` |
| Modify | `lib/features/auth/domain/usecases/sign_up_usecase.dart` | Implement `call` |
| Modify | `lib/features/auth/domain/usecases/sign_out_usecase.dart` | Implement `call` |
| Modify | `lib/features/auth/data/datasources/auth_remote_datasource.dart` | Implement datasource |
| Modify | `lib/features/auth/data/repositories/auth_repository_impl.dart` | Implement repository |
| Modify | `lib/features/auth/presentation/providers/auth_provider.dart` | Wire Riverpod providers |
| Modify | `lib/features/auth/presentation/screens/login_screen.dart` | Email/password form |
| Modify | `lib/features/auth/presentation/screens/register_screen.dart` | Registration + role picker |
| Modify | `lib/features/auth/presentation/screens/role_router_screen.dart` | Role-based redirect |
| Modify | `lib/app/router.dart` | Routes + redirect guard (`routerProvider`) |
| Modify | `lib/app/app.dart` | `ConsumerWidget`, watch `routerProvider` |

## API Contracts

```dart
// domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Stream<AppUser?> watchAuthState();
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({required String name, required String email, required String password, required UserRole role});
  Future<void> signOut();
}

// domain/entities/app_user.dart (unchanged)
enum UserRole { donor, driver, beneficiary }
class AppUser { uid, name, email, role }

// presentation/providers/auth_provider.dart
authDatasourceProvider  → AuthRemoteDatasource
authRepositoryProvider  → AuthRepository
authStateProvider       → StreamProvider<AppUser?>
signInUsecaseProvider   → SignInUsecase
signUpUsecaseProvider   → SignUpUsecase
signOutUsecaseProvider  → SignOutUsecase

// app/router.dart
routerProvider          → GoRouter (with redirect guard)
```

## Key Design Notes

- **UserRole name collision**: `app_user.dart` (domain) and `user_model.dart` (data) both declare `UserRole`. `AuthRepositoryImpl` imports `user_model.dart` aliased as `m` to resolve the conflict.
- **Router reactivity**: `_AuthChangeNotifier extends ChangeNotifier` listens to `authStateProvider` via `ref.listen` and calls `notifyListeners()`, which triggers GoRouter's `refreshListenable` to re-evaluate the redirect.
- **`RoleRouterScreen`**: Uses `initState` + `ref.listen` to navigate as soon as auth state resolves. GoRouter redirect handles `/login`↔auth-route bouncing; this screen handles role→dashboard dispatch.

## Test Plan

| Test file | Covers |
|-----------|--------|
| `test/unit/features/auth/sign_in_usecase_test.dart` | SignInUsecase delegates to repository |
| `test/unit/features/auth/sign_up_usecase_test.dart` | SignUpUsecase delegates to repository |
| `test/unit/features/auth/auth_repository_impl_test.dart` | Role mapping, null-user stream handling |
| `test/widget/features/auth/login_screen_test.dart` | Form validation, loading state, error display |
| `test/widget/features/auth/register_screen_test.dart` | Role picker, form submission |

## Out of Scope

- Google Sign-In / OAuth providers
- Password reset / forgot-password flow
- Email verification
- Profile editing
- Donor/Driver/Beneficiary dashboard implementations (screens remain stubs)

## Open Questions

None.
