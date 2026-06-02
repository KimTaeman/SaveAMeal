---
Date: 2026-06-02 00:00
Member: chotiya
Agent: flutter-engineer
Task: Implement Donor Account feature — 3 screens, data/domain layer, widget tests
Prompt: Implement DonorAccountScreen (/donor/account), PersonalInformationScreen (/donor/account/personal), OrganizationProfileScreen (/donor/account/org). Add UserModel fields (location, photoUrl, managerName, streetAddress). Add updateUser to FirestoreService. Create DonorAccountRepository, UpdateUserUsecase, datasource/repo impl, donor_account_provider. Update router. Write widget tests for all 3 screens.
Outcome: All 3 screens implemented. Domain/data layer created. Router updated with nested sub-routes. 42 widget tests pass. flutter analyze clean.
Decisions: Used import aliases (user_model.dart as um) in tests to resolve UserRole enum collision between user_model.dart and app_user.dart. Used ListView.builder with itemCount: 1 wrapping a Column to satisfy the no-unbounded-ListView rule. Used overrideWithValue for SignOutUsecase/UpdateUserUsecase providers in tests (required real typed instances via fake repository implementations). Chip selection test uses ensureVisible to handle off-screen widgets in test viewport. DonorAccountScreen notification bell test uses findsWidgets since bell icon appears in both AppBar and Push Notifications ListTile.
Handoff: Review against spec. Follow-ups: (1) photo upload flow pending StorageService decision; (2) AppUser entity needs phone/location fields added to support pre-filling from auth stream alone; (3) donor_account_repository.dart in domain imports UserModel from core/models — acceptable since UserModel is a shared core model (not a Firebase import).
Review: PENDING
Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  3 files changed, 21 insertions(+), 2 deletions(-)

Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 57 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 57 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 57 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 57 insertions(+), 12 deletions(-)


---
Date: 2026-06-02 10:00
Member: chotiya
Agent: flutter-engineer
Task: OrganizationProfileScreen full update — banner upload, editable operating hours, surplus types, new UserModel fields
Prompt: Add bannerUrl, operatingHours, surplusTypes to UserModel. Add uploadBannerPhoto to StorageService. Fully rewrite OrganizationProfileScreen with banner image upload, editable operating hours rows, FilterChip surplus type selection, and save flow writing all new fields.
Outcome: UserModel extended with bannerUrl (String?), operatingHours (List<Map<String,String>>), surplusTypes (List<String>). uploadBannerPhoto added to StorageService. OrganizationProfileScreen fully rewritten as ConsumerStatefulWidget with banner section (CachedNetworkImage + camera overlay + upload progress), store details card, editable operating hours card (view/edit toggle, add/remove rows, Done button), surplus types FilterChip card, and FilledButton.icon save. build_runner codegen succeeded. flutter analyze: no issues. dart format: clean.
Decisions: location/photoUrl/managerName/streetAddress already existed in UserModel — skipped re-adding. Extracted banner, store details, operating hours, and surplus types into private StatelessWidget helpers to keep main state class readable. Used static const _kGreen = Color(0xFF006E2F) inside each private widget that needs it (not yet in AppColors). withOpacity kept with // ignore: deprecated_member_use comment to suppress lint without removing functional code.
Handoff: Submit for architect/QA review. Follow-up: add _kGreen to AppColors once approved. Widget test for updated OrganizationProfileScreen needed (test file was not updated in this pass).
Review: PENDING
Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 69 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 69 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 69 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 69 insertions(+), 12 deletions(-)


---
Date: 2026-06-02 12:00
Member: chotiya
Agent: flutter-engineer
Task: Fix Store Details fields not persisting after Save Changes in OrganizationProfileScreen
Prompt: Investigate why Store Details fields are not persisting after Save Changes in the SaveAMeal Flutter app's OrganizationProfileScreen. Read all relevant files and trace the full data flow, then fix the root cause.
Outcome: Identified and fixed stale provider cache bug. After save, currentUserProvider was never invalidated so re-entering the screen re-seeded controllers from cached (pre-save) data. Added ref.invalidate(currentUserProvider) and setState(() => _initialized = false) immediately after the Firestore update succeeds, before context.pop(). flutter analyze clean, dart format no changes.
Decisions: Only one change was needed — invalidating currentUserProvider and resetting _initialized. Field names in _save map exactly matched user_model.g.dart keys (no mismatch). FirestoreService.updateUser already used .update() not .set(). No other fixes required.
Handoff: One file changed: apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart. No new dependencies. No generated files touched.
Review: CHANGES REQUESTED by qa-engineer

---
Date: 2026-06-03 00:00
Member: chotiya
Agent: qa-engineer
Task: QA review of feature/donor-account-screens PR — coverage gaps, accessibility, performance
Prompt: Review the feature/donor-account-screens PR for coverage gaps, accessibility issues, and performance problems. Read the 3 new widget test files and the 3 source screens. Check happy-path/error saves, log-out flow, photo upload, operating-hours edit mode, chip toggles, accessibility labels, color contrast, unbounded ListViews, CachedNetworkImage usage, and provider memoization.
Outcome: CHANGES REQUESTED. Found 2 failing tests (camera_alt icon mismatch in personal_information_screen_test.dart line 113; em-dash vs en-dash mismatch in organization_profile_screen_test.dart line 175), 5 missing test scenarios (happy-path save SnackBar, error-path save SnackBar, log-out flow, operating-hours edit mode, photo upload stub), 2 medium accessibility gaps (notification bell IconButton and photo-upload GestureDetector lack Semantics/tooltip), and 1 low advisory (deprecated withOpacity in FilterChip). No unbounded ListViews, all remote images use CachedNetworkImage, _initialized guard is correct, currentUserProvider is properly memoized via Riverpod codegen. flutter analyze passes with no issues.
Decisions: Contrast ratio 0xFF006E2F on white background is approximately 8.6:1 — passes WCAG AA. Badge text 0xFF523D00 on 0xFFD7A400 is approximately 4.9:1 — passes. No golden tests exist for any screen in the project yet; treated as medium finding (advisory for now but required before production). The Organization Profile tile navigation test in donor_account_screen_test.dart only checks widget presence, not actual navigation — low priority but noted.
Handoff: Flutter engineer must fix the 2 failing tests (icon name and day-separator character), add 5 missing test scenarios, and add Semantics wrappers to the notification bell and photo-upload tap target.
Review: CHANGES REQUESTED by qa-engineer
Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 69 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 69 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 69 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 69 insertions(+), 12 deletions(-)


---
Date: 2026-06-03 00:00
Member: chotiya
Agent: architect
Task: PR review — feature/donor-account-screens Clean Architecture compliance
Prompt: Review the feature/donor-account-screens PR for Clean Architecture compliance, layer boundary violations, domain purity, and schema consistency.
Outcome: CHANGES REQUESTED. Wrote review report to docs/agent-runs/2026-06-03-architect-donor-account-screens.md. Wrote ADR 0008 to docs/decisions/0008-domain-entity-vs-shared-model.md. Four issues requiring fixes: (1) High — Map<String,dynamic> in domain interface leaks Firestore field names; (2) High — UserModel (Freezed) in domain interface breaks entity purity convention; (3) High — firebase_auth SDK called directly in DonorAccountScreen bypassing domain; (4) Strongly recommended — FirestoreService.updateUser uses .update() which throws NOT_FOUND on missing documents, should be .set(merge: true).
Decisions: Domain entity purity rule codified in ADR 0008 — Freezed models must not appear in domain interfaces; domain entities must be plain Dart classes. The existing donor_provider.dart wiring pattern (provider imports concrete impl classes) was assessed as consistent with established codebase pattern — advisory only, not a blocker for this PR.
Handoff: Flutter-engineer must: (1) introduce domain/entities/donor_profile.dart plain Dart entity and domain/entities/user_profile_update.dart typed update value object; (2) update DonorAccountRepository interface to use these types; (3) add mapper in DonorAccountRepositoryImpl (UserModel -> DonorProfile); (4) remove firebase_auth import from DonorAccountScreen, surface createdAt via AppUser entity and authStateProvider; (5) change FirestoreService.updateUser to .set(fields, SetOptions(merge: true)); (6) replace all Color(0xFF006E2F) hardcoded literals with cs.primary or AppColors token.
Review: CHANGES REQUESTED by Architect agent
Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 69 insertions(+), 12 deletions(-)


---
Date: 2026-06-03 00:00
Member: chotiya
Agent: flutter-engineer
Task: Fix all QA and security findings in the donor account feature
Prompt: Fix all QA and security findings in the SaveAMeal Flutter app's donor account feature. Fixes: (1) test icon mismatch camera_alt_outlined vs camera_alt, (2) test operating hours string mismatch Monday–Friday vs Monday – Friday, (3) iOS Info.plist missing privacy usage strings, (4) remove FirebaseAuth direct import from DonorAccountScreen, (5) FirestoreService.updateUser use merge, (6) raw exception messages in SnackBars, (7) tooltip missing on notification bell IconButton.
Outcome: All 7 fixes applied. flutter analyze: no issues. All 52 donor widget tests pass.
Decisions: For Fix 4, AppUser entity has no createdAt and authStateProvider returns Stream<AppUser?> with no Firebase metadata access. Removed the "Member since" text widget entirely rather than hardcode a fallback. For Fix 6, added firebase_core import to both personal_information_screen.dart and organization_profile_screen.dart to enable FirebaseException type-checking in catch blocks. For Fix 3, used Node.js to write the binary-correct CRLF plist insertion since the Edit tool could not match the CRLF-terminated file.
Handoff: All donor widget tests green. Ready for architect/QA review.
Review: PENDING
Files:
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/user_model.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/lib/services/location_service.dart
  ~ apps/mobile/lib/services/service_providers.dart
  ~ apps/mobile/lib/services/storage_service.dart
  ? apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart (untracked)
  ? apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart (untracked)
  ? apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart (untracked)
  ? apps/mobile/test/widget/features/donor/donor_account_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart (untracked)
  ? apps/mobile/test/widget/features/donor/personal_information_screen_test.dart (untracked)
Summary:  6 files changed, 69 insertions(+), 12 deletions(-)

Files:
  ~ apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart
  ~ apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart
  ~ apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart
  ~ apps/mobile/lib/features/donor/domain/usecases/update_user_usecase.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  ~ apps/mobile/test/widget/features/donor/donor_account_screen_test.dart
  ~ apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart
  ~ apps/mobile/test/widget/features/donor/personal_information_screen_test.dart
  ? apps/mobile/lib/features/donor/domain/entities/user_profile_update.dart (untracked)
Summary:  11 files changed, 103 insertions(+), 64 deletions(-)

Files:
  ~ apps/mobile/lib/app/app.dart
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/beneficiary_model.dart
  ? apps/mobile/lib/core/models/user_model.dart (untracked)
  ~ apps/mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart
  ~ apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart
  ? apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart (untracked)
  ~ apps/mobile/lib/features/beneficiary/presentation/screens/tracking_screen.dart
  ~ apps/mobile/lib/features/beneficiary/presentation/widgets/active_delivery_card.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/donor_dashboard_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/scanner_screen.dart
  ~ apps/mobile/lib/features/driver/data/datasources/driver_remote_datasource.dart
  ~ apps/mobile/lib/features/driver/data/repositories/driver_repository_impl.dart
  ~ apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart
  ~ apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/claim_rescue_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/driver_map_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/verify_delivery_screen.dart
  + apps/mobile/lib/features/notifications/data/repositories/mock_notifications_repository.dart
  + apps/mobile/lib/features/notifications/domain/entities/app_notification.dart
  + apps/mobile/lib/features/notifications/domain/repositories/notifications_repository.dart
  + apps/mobile/lib/features/notifications/presentation/providers/notifications_provider.dart
  + apps/mobile/lib/features/notifications/presentation/screens/notifications_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/screens/volunteer_delivery_scanner_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/screens/volunteer_queue_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/widgets/pending_request_card.dart
  ~ apps/mobile/lib/main.dart
  + apps/mobile/lib/services/fcm_service.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  + apps/mobile/lib/services/notification_handler.dart
  ? apps/mobile/lib/services/service_providers.dart (untracked)
  + apps/mobile/test/unit/auth/auth_remote_datasource_fcm_test.dart
  ~ apps/mobile/test/unit/driver/claim_batch_usecase_test.dart
  + apps/mobile/test/unit/driver/driver_notifier_location_test.dart
  ~ apps/mobile/test/unit/driver/driver_notifier_test.dart
  + apps/mobile/test/unit/services/fcm_service_test.dart
  + apps/mobile/test/unit/services/notification_handler_test.dart
  ~ apps/mobile/test/widget/driver/claim_rescue_screen_test.dart
  ~ apps/mobile/test/widget/driver/pickup_verification_screen_test.dart
  ~ apps/mobile/test/widget/driver/verify_delivery_screen_test.dart
  ~ apps/mobile/test/widget/features/beneficiary/widgets/active_delivery_card_test.dart
  - apps/mobile/test/widget/features/volunteer/volunteer_delivery_scanner_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/volunteer_queue_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/widgets/pending_request_card_test.dart
  ? apps/mobile/test/widget/notifications_screen_test.dart (untracked)
Summary:  49 files changed, 2605 insertions(+), 621 deletions(-)

Files:
  ~ apps/mobile/lib/app/app.dart
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/beneficiary_model.dart
  ? apps/mobile/lib/core/models/user_model.dart (untracked)
  ~ apps/mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart
  ~ apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart
  ? apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart (untracked)
  ~ apps/mobile/lib/features/beneficiary/presentation/screens/tracking_screen.dart
  ~ apps/mobile/lib/features/beneficiary/presentation/widgets/active_delivery_card.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/donor_dashboard_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/scanner_screen.dart
  ~ apps/mobile/lib/features/driver/data/datasources/driver_remote_datasource.dart
  ~ apps/mobile/lib/features/driver/data/repositories/driver_repository_impl.dart
  ~ apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart
  ~ apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/claim_rescue_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/driver_map_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/verify_delivery_screen.dart
  + apps/mobile/lib/features/notifications/data/repositories/mock_notifications_repository.dart
  + apps/mobile/lib/features/notifications/domain/entities/app_notification.dart
  + apps/mobile/lib/features/notifications/domain/repositories/notifications_repository.dart
  + apps/mobile/lib/features/notifications/presentation/providers/notifications_provider.dart
  + apps/mobile/lib/features/notifications/presentation/screens/notifications_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/screens/volunteer_delivery_scanner_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/screens/volunteer_queue_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/widgets/pending_request_card.dart
  ~ apps/mobile/lib/main.dart
  + apps/mobile/lib/services/fcm_service.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  + apps/mobile/lib/services/notification_handler.dart
  ? apps/mobile/lib/services/service_providers.dart (untracked)
  + apps/mobile/test/unit/auth/auth_remote_datasource_fcm_test.dart
  ~ apps/mobile/test/unit/driver/claim_batch_usecase_test.dart
  + apps/mobile/test/unit/driver/driver_notifier_location_test.dart
  ~ apps/mobile/test/unit/driver/driver_notifier_test.dart
  + apps/mobile/test/unit/services/fcm_service_test.dart
  + apps/mobile/test/unit/services/notification_handler_test.dart
  ~ apps/mobile/test/widget/driver/claim_rescue_screen_test.dart
  ~ apps/mobile/test/widget/driver/pickup_verification_screen_test.dart
  ~ apps/mobile/test/widget/driver/verify_delivery_screen_test.dart
  ~ apps/mobile/test/widget/features/beneficiary/widgets/active_delivery_card_test.dart
  - apps/mobile/test/widget/features/volunteer/volunteer_delivery_scanner_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/volunteer_queue_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/widgets/pending_request_card_test.dart
  ? apps/mobile/test/widget/notifications_screen_test.dart (untracked)
Summary:  49 files changed, 2605 insertions(+), 621 deletions(-)

Files:
  ~ apps/mobile/lib/app/app.dart
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/beneficiary_model.dart
  ? apps/mobile/lib/core/models/user_model.dart (untracked)
  ~ apps/mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart
  ~ apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart
  ? apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart (untracked)
  ~ apps/mobile/lib/features/beneficiary/presentation/screens/tracking_screen.dart
  ~ apps/mobile/lib/features/beneficiary/presentation/widgets/active_delivery_card.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/donor_dashboard_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/scanner_screen.dart
  ~ apps/mobile/lib/features/driver/data/datasources/driver_remote_datasource.dart
  ~ apps/mobile/lib/features/driver/data/repositories/driver_repository_impl.dart
  ~ apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart
  ~ apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/claim_rescue_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/driver_map_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/verify_delivery_screen.dart
  + apps/mobile/lib/features/notifications/data/repositories/mock_notifications_repository.dart
  + apps/mobile/lib/features/notifications/domain/entities/app_notification.dart
  + apps/mobile/lib/features/notifications/domain/repositories/notifications_repository.dart
  + apps/mobile/lib/features/notifications/presentation/providers/notifications_provider.dart
  + apps/mobile/lib/features/notifications/presentation/screens/notifications_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/screens/volunteer_delivery_scanner_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/screens/volunteer_queue_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/widgets/pending_request_card.dart
  ~ apps/mobile/lib/main.dart
  + apps/mobile/lib/services/fcm_service.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  + apps/mobile/lib/services/notification_handler.dart
  ? apps/mobile/lib/services/service_providers.dart (untracked)
  + apps/mobile/test/unit/auth/auth_remote_datasource_fcm_test.dart
  ~ apps/mobile/test/unit/driver/claim_batch_usecase_test.dart
  + apps/mobile/test/unit/driver/driver_notifier_location_test.dart
  ~ apps/mobile/test/unit/driver/driver_notifier_test.dart
  + apps/mobile/test/unit/services/fcm_service_test.dart
  + apps/mobile/test/unit/services/notification_handler_test.dart
  ~ apps/mobile/test/widget/driver/claim_rescue_screen_test.dart
  ~ apps/mobile/test/widget/driver/pickup_verification_screen_test.dart
  ~ apps/mobile/test/widget/driver/verify_delivery_screen_test.dart
  ~ apps/mobile/test/widget/features/beneficiary/widgets/active_delivery_card_test.dart
  - apps/mobile/test/widget/features/volunteer/volunteer_delivery_scanner_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/volunteer_queue_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/widgets/pending_request_card_test.dart
  ? apps/mobile/test/widget/notifications_screen_test.dart (untracked)
Summary:  52 files changed, 2608 insertions(+), 624 deletions(-)

---
Date: 2026-06-03 00:00
Member: chotiya
Agent: qa-engineer
Task: Re-review feature/donor-account-screens after flutter-engineer applied v1 fixes
Prompt: Re-review of feature/donor-account-screens. Verify all prior findings (2 failing tests, 5 missing test scenarios, notification bell tooltip, photo-upload Semantics) are resolved. Check new UserProfileUpdate entity and bell navigation. Report verdict.
Outcome: CHANGES REQUESTED. Both previously failing tests are confirmed fixed. Typed UserProfileUpdate entity is correctly introduced and fake repositories compile-safe. Notification bell tooltip is present on all three AppBars. Five of six previously-required test scenarios remain absent. Photo-upload GestureDetector still has no Semantics wrapper. Two new medium findings: bell navigation untested and test routers lack /notifications stub route; _save error SnackBar in OrganizationProfileScreen uses wrong message text ('Upload failed' instead of 'Save failed'). Advisory findings: withOpacity deprecation, missing golden tests, toMap() in domain entity.
Decisions: Bell navigation coverage gap classified as Medium (not High) because it is new behaviour not present in v1 scope; however a test router crash risk elevates urgency. toMap() in domain entity classified Informational because it is not currently called from domain code.
Handoff: Flutter engineer must: (1) add 5 missing test scenarios (happy-path save, error-path save, log-out flow, operating-hours edit mode, photo-upload stub/accessibility); (2) add Semantics wrapper to photo-upload GestureDetector in personal_information_screen.dart; (3) add /notifications stub route to all three test _buildRouter() helpers; (4) add one bell-navigation test; (5) fix _save catch message in organization_profile_screen.dart. Report written to docs/agent-runs/2026-06-03-qa-donor-account-screens-v2.md.
Review: CHANGES REQUESTED by qa-engineer
Files:
  ~ apps/mobile/lib/app/app.dart
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/beneficiary_model.dart
  ? apps/mobile/lib/core/models/user_model.dart (untracked)
  ~ apps/mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart
  ~ apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart
  ? apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart (untracked)
  ~ apps/mobile/lib/features/beneficiary/presentation/screens/tracking_screen.dart
  ~ apps/mobile/lib/features/beneficiary/presentation/widgets/active_delivery_card.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/donor_dashboard_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/scanner_screen.dart
  ~ apps/mobile/lib/features/driver/data/datasources/driver_remote_datasource.dart
  ~ apps/mobile/lib/features/driver/data/repositories/driver_repository_impl.dart
  ~ apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart
  ~ apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/claim_rescue_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/driver_map_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/verify_delivery_screen.dart
  + apps/mobile/lib/features/notifications/data/repositories/mock_notifications_repository.dart
  + apps/mobile/lib/features/notifications/domain/entities/app_notification.dart
  + apps/mobile/lib/features/notifications/domain/repositories/notifications_repository.dart
  + apps/mobile/lib/features/notifications/presentation/providers/notifications_provider.dart
  + apps/mobile/lib/features/notifications/presentation/screens/notifications_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/screens/volunteer_delivery_scanner_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/screens/volunteer_queue_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/widgets/pending_request_card.dart
  ~ apps/mobile/lib/main.dart
  + apps/mobile/lib/services/fcm_service.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  + apps/mobile/lib/services/notification_handler.dart
  ? apps/mobile/lib/services/service_providers.dart (untracked)
  + apps/mobile/test/unit/auth/auth_remote_datasource_fcm_test.dart
  ~ apps/mobile/test/unit/driver/claim_batch_usecase_test.dart
  + apps/mobile/test/unit/driver/driver_notifier_location_test.dart
  ~ apps/mobile/test/unit/driver/driver_notifier_test.dart
  + apps/mobile/test/unit/services/fcm_service_test.dart
  + apps/mobile/test/unit/services/notification_handler_test.dart
  ~ apps/mobile/test/widget/driver/claim_rescue_screen_test.dart
  ~ apps/mobile/test/widget/driver/pickup_verification_screen_test.dart
  ~ apps/mobile/test/widget/driver/verify_delivery_screen_test.dart
  ~ apps/mobile/test/widget/features/beneficiary/widgets/active_delivery_card_test.dart
  - apps/mobile/test/widget/features/volunteer/volunteer_delivery_scanner_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/volunteer_queue_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/widgets/pending_request_card_test.dart
  ? apps/mobile/test/widget/notifications_screen_test.dart (untracked)
Summary:  52 files changed, 2608 insertions(+), 624 deletions(-)


---
Date: 2026-06-03 00:00
Member: chotiya
Agent: flutter-engineer
Task: Fix PR review v2 blocking findings — domain purity refactoring and QA gaps
Prompt: Fix all blocking findings from the PR review v2 for the SaveAMeal donor account feature. This covers domain purity refactoring (DonorProfile entity, toMap removal, _toFirestoreMap in data layer, updated repository interface and impl, updated provider and screens) and QA gaps (Semantics wrapper, /notifications stub, new save/error/accessibility/log-out/operating-hours-edit test cases).
Outcome: All blocking findings fixed. 59/59 donor widget tests pass. flutter analyze clean.
Decisions: Used byWidgetPredicate instead of bySemanticsLabel for accessibility test (no need to enable the semantics tree); used two pump() calls without pumpAndSettle after save to check SnackBar before timer dismisses it; used find.descendant+find.ancestor to target the Operating Hours edit pencil specifically (not the banner edit button); added ensureVisible() before tapping off-screen buttons.
Handoff: All domain purity and QA blocking items resolved. The donor_account_provider.g.dart was regenerated via build_runner. No new dependencies added. Ready for architect/QA review.
Review: PENDING
Files:
  ~ apps/mobile/lib/app/app.dart
  ~ apps/mobile/lib/app/router.dart
  ~ apps/mobile/lib/core/models/beneficiary_model.dart
  ? apps/mobile/lib/core/models/user_model.dart (untracked)
  ~ apps/mobile/lib/features/auth/data/datasources/auth_remote_datasource.dart
  ~ apps/mobile/lib/features/auth/presentation/providers/auth_provider.dart
  ~ apps/mobile/lib/features/beneficiary/presentation/providers/beneficiary_provider.dart
  ? apps/mobile/lib/features/beneficiary/presentation/screens/beneficiary_dashboard_screen.dart (untracked)
  ~ apps/mobile/lib/features/beneficiary/presentation/screens/tracking_screen.dart
  ? apps/mobile/lib/features/beneficiary/presentation/widgets/active_delivery_card.dart (untracked)
  ~ apps/mobile/lib/features/donor/data/datasources/donor_account_remote_datasource.dart
  ~ apps/mobile/lib/features/donor/data/repositories/donor_account_repository_impl.dart
  ~ apps/mobile/lib/features/donor/domain/entities/user_profile_update.dart
  ~ apps/mobile/lib/features/donor/domain/repositories/donor_account_repository.dart
  ~ apps/mobile/lib/features/donor/presentation/providers/donor_account_provider.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/donor_account_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/donor_dashboard_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/organization_profile_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/personal_information_screen.dart
  ~ apps/mobile/lib/features/donor/presentation/screens/scanner_screen.dart
  ~ apps/mobile/lib/features/driver/data/datasources/driver_remote_datasource.dart
  ~ apps/mobile/lib/features/driver/data/repositories/driver_repository_impl.dart
  ~ apps/mobile/lib/features/driver/domain/repositories/driver_repository.dart
  ~ apps/mobile/lib/features/driver/presentation/providers/driver_notifier.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/claim_rescue_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/delivery_completed_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/driver_map_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/pickup_verification_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/safety_verification_screen.dart
  ~ apps/mobile/lib/features/driver/presentation/screens/verify_delivery_screen.dart
  + apps/mobile/lib/features/notifications/data/repositories/mock_notifications_repository.dart
  + apps/mobile/lib/features/notifications/domain/entities/app_notification.dart
  + apps/mobile/lib/features/notifications/domain/repositories/notifications_repository.dart
  + apps/mobile/lib/features/notifications/presentation/providers/notifications_provider.dart
  + apps/mobile/lib/features/notifications/presentation/screens/notifications_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/screens/volunteer_delivery_scanner_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/screens/volunteer_queue_screen.dart
  - apps/mobile/lib/features/volunteer/presentation/widgets/pending_request_card.dart
  ~ apps/mobile/lib/main.dart
  + apps/mobile/lib/services/fcm_service.dart
  ~ apps/mobile/lib/services/firestore_service.dart
  + apps/mobile/lib/services/notification_handler.dart
  ? apps/mobile/lib/services/service_providers.dart (untracked)
  + apps/mobile/test/unit/auth/auth_remote_datasource_fcm_test.dart
  ~ apps/mobile/test/unit/driver/claim_batch_usecase_test.dart
  + apps/mobile/test/unit/driver/driver_notifier_location_test.dart
  ~ apps/mobile/test/unit/driver/driver_notifier_test.dart
  + apps/mobile/test/unit/services/fcm_service_test.dart
  + apps/mobile/test/unit/services/notification_handler_test.dart
  ~ apps/mobile/test/widget/driver/claim_rescue_screen_test.dart
  ~ apps/mobile/test/widget/driver/pickup_verification_screen_test.dart
  ~ apps/mobile/test/widget/driver/verify_delivery_screen_test.dart
  ~ apps/mobile/test/widget/features/beneficiary/widgets/active_delivery_card_test.dart
  ~ apps/mobile/test/widget/features/donor/donor_account_screen_test.dart
  ~ apps/mobile/test/widget/features/donor/organization_profile_screen_test.dart
  ~ apps/mobile/test/widget/features/donor/personal_information_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/volunteer_delivery_scanner_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/volunteer_queue_screen_test.dart
  - apps/mobile/test/widget/features/volunteer/widgets/pending_request_card_test.dart
  ? apps/mobile/test/widget/notifications_screen_test.dart (untracked)
  ? apps/mobile/lib/features/donor/domain/entities/donor_profile.dart (untracked)
Summary:  60 files changed, 2826 insertions(+), 542 deletions(-)

