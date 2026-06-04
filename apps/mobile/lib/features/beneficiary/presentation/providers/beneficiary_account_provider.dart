import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/data/datasources/beneficiary_account_remote_datasource.dart';
import 'package:saveameal/features/beneficiary/data/repositories/beneficiary_account_repository_impl.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';
import 'package:saveameal/features/beneficiary/domain/entities/order_history_entry.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/beneficiary_account_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/update_org_profile_usecase.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/update_personal_info_usecase.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/watch_beneficiary_profile_usecase.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/watch_order_history_usecase.dart';
import 'package:saveameal/services/service_providers.dart';

part 'beneficiary_account_provider.g.dart';

// ── DI wiring ────────────────────────────────────────────────────────────────

@riverpod
BeneficiaryAccountRemoteDatasource beneficiaryAccountRemoteDatasource(
  Ref ref,
) =>
    BeneficiaryAccountRemoteDatasourceImpl(ref.watch(firestoreServiceProvider));

@riverpod
BeneficiaryAccountRepository beneficiaryAccountRepository(Ref ref) =>
    BeneficiaryAccountRepositoryImpl(
      ref.watch(beneficiaryAccountRemoteDatasourceProvider),
    );

@riverpod
WatchBeneficiaryProfileUseCase watchBeneficiaryProfileUseCase(Ref ref) =>
    WatchBeneficiaryProfileUseCase(
      ref.watch(beneficiaryAccountRepositoryProvider),
    );

@riverpod
UpdatePersonalInfoUseCase updatePersonalInfoUseCase(Ref ref) =>
    UpdatePersonalInfoUseCase(ref.watch(beneficiaryAccountRepositoryProvider));

@riverpod
UpdateOrgProfileUseCase updateOrgProfileUseCase(Ref ref) =>
    UpdateOrgProfileUseCase(ref.watch(beneficiaryAccountRepositoryProvider));

@riverpod
WatchOrderHistoryUseCase watchOrderHistoryUseCase(Ref ref) =>
    WatchOrderHistoryUseCase(ref.watch(beneficiaryAccountRepositoryProvider));

// ── Stream providers ─────────────────────────────────────────────────────────

@riverpod
Stream<BeneficiaryProfile?> currentBeneficiaryProfile(Ref ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';
  if (uid.isEmpty) return Stream.value(null);
  return ref.watch(watchBeneficiaryProfileUseCaseProvider).call(uid);
}

// ── Order History ─────────────────────────────────────────────────────────────

class OrderHistoryState {
  const OrderHistoryState({
    this.entries = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.lastEntryId,
  });

  final List<OrderHistoryEntry> entries;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final String? lastEntryId;

  OrderHistoryState copyWith({
    List<OrderHistoryEntry>? entries,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    String? lastEntryId,
  }) => OrderHistoryState(
    entries: entries ?? this.entries,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: error ?? this.error,
    lastEntryId: lastEntryId ?? this.lastEntryId,
  );
}

@riverpod
class OrderHistoryNotifier extends _$OrderHistoryNotifier {
  @override
  OrderHistoryState build(String uid) => const OrderHistoryState();

  Future<void> loadMore() async {
    // TODO: implement pagination once backend is decided.
  }
}
