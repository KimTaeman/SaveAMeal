import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/domain/repositories/intake_repository.dart';
import 'package:saveameal/features/beneficiary/domain/usecases/confirm_receipt_usecase.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/confirm_receipt_provider.dart';
import 'package:saveameal/features/beneficiary/domain/entities/delivery_history_page.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request.dart';
import 'package:saveameal/features/beneficiary/domain/entities/intake_request_detail.dart';
import 'package:saveameal/features/beneficiary/domain/entities/recent_delivery.dart';

const _kBatchId = 'batch_test_001';
const _kUserId = 'user_001';

// Fake repository that captures calls and can be configured to throw.
class _FakeRepo implements IntakeRepository {
  String? capturedBatchId;
  String? capturedBeneficiaryId;
  int? capturedRating;
  String? capturedFeedback;
  int callCount = 0;
  Exception? throwOnCall;

  @override
  Future<void> confirmReceipt({
    required String batchId,
    required String beneficiaryId,
    int? rating,
    String? feedback,
  }) async {
    callCount++;
    if (throwOnCall != null) throw throwOnCall!;
    capturedBatchId = batchId;
    capturedBeneficiaryId = beneficiaryId;
    capturedRating = rating;
    capturedFeedback = feedback;
  }

  @override
  Stream<List<IntakeRequest>> watchActiveDeliveries(String b) =>
      throw UnimplementedError();

  @override
  Stream<IntakeRequest?> watchIntakeRequest(String b) =>
      throw UnimplementedError();

  @override
  Stream<List<IntakeRequest>> watchVolunteerQueue(String v) =>
      throw UnimplementedError();

  @override
  Future<void> acceptDeliveryJob({
    required String batchId,
    required String volunteerId,
    required String volunteerName,
  }) => throw UnimplementedError();

  @override
  Future<void> confirmDelivery({
    required String batchId,
    required String volunteerId,
  }) => throw UnimplementedError();

  @override
  Future<void> toggleIntakeStatus({
    required String beneficiaryId,
    required BeneficiaryIntakeAvailability availability,
  }) => throw UnimplementedError();

  @override
  Stream<BeneficiaryIntakeAvailability> watchIntakeAvailability(String b) =>
      throw UnimplementedError();

  @override
  Stream<IntakeRequestDetail?> watchIntakeRequestDetail(
    String batchId,
    String beneficiaryId,
  ) => throw UnimplementedError();

  @override
  Stream<List<RecentDelivery>> watchRecentDeliveries(String b) =>
      throw UnimplementedError();

  @override
  Future<DeliveryHistoryPage> fetchDeliveryHistoryPage({
    required String beneficiaryId,
    required int pageSize,
    Object? cursor,
  }) => throw UnimplementedError();
}

const _fakeUser = AppUser(
  uid: _kUserId,
  name: 'Test User',
  email: 'test@example.com',
  role: UserRole.beneficiary,
);

ProviderContainer _makeContainer(
  _FakeRepo fakeRepo, {
  AppUser? user = _fakeUser,
}) {
  return ProviderContainer(
    overrides: [
      confirmReceiptUseCaseProvider.overrideWithValue(
        ConfirmReceiptUseCase(fakeRepo),
      ),
      authStateProvider.overrideWith((_) async* {
        yield user;
      }),
    ],
  );
}

/// Waits for [authStateProvider] to emit its first value in [container].
/// Keeps a live subscription to prevent autoDispose from firing.
Future<ProviderSubscription<AsyncValue<AppUser?>>> _waitForAuth(
  ProviderContainer container,
) async {
  // A live subscription prevents the autoDispose provider from being evicted.
  final sub = container.listen<AsyncValue<AppUser?>>(
    authStateProvider,
    (prev, next) {},
    fireImmediately: true,
  );
  // Yield to event loop until the stream emits.
  while (container.read(authStateProvider).isLoading) {
    await Future<void>.microtask(() {});
  }
  return sub;
}

void main() {
  group('ConfirmReceiptNotifier', () {
    // (1) initial state
    test(
      'initial state: rating==0, feedback==empty, isSubmitting==false, error==null, submitted==false',
      () async {
        final container = _makeContainer(_FakeRepo());
        addTearDown(container.dispose);

        // Wait for auth stream to settle.
        await container.pump();

        final state = container.read(confirmReceiptProvider(_kBatchId));
        expect(state.rating, 0);
        expect(state.feedback, '');
        expect(state.isSubmitting, false);
        expect(state.error, isNull);
        expect(state.submitted, false);
      },
    );

    // (2) setRating(3) sets rating=3
    test('setRating(3) sets rating to 3', () async {
      final container = _makeContainer(_FakeRepo());
      addTearDown(container.dispose);

      container.read(confirmReceiptProvider(_kBatchId).notifier).setRating(3);

      expect(container.read(confirmReceiptProvider(_kBatchId)).rating, 3);
    });

    // (3) setRating(3) twice deselects → rating=0
    test('setRating(3) twice deselects → rating=0', () async {
      final container = _makeContainer(_FakeRepo());
      addTearDown(container.dispose);

      final notifier = container.read(
        confirmReceiptProvider(_kBatchId).notifier,
      );
      notifier.setRating(3);
      notifier.setRating(3);

      expect(container.read(confirmReceiptProvider(_kBatchId)).rating, 0);
    });

    // (4) setRating(5) then setRating(2) → rating=2
    test('setRating(5) then setRating(2) → rating=2', () async {
      final container = _makeContainer(_FakeRepo());
      addTearDown(container.dispose);

      final notifier = container.read(
        confirmReceiptProvider(_kBatchId).notifier,
      );
      notifier.setRating(5);
      notifier.setRating(2);

      expect(container.read(confirmReceiptProvider(_kBatchId)).rating, 2);
    });

    // (5) setFeedback updates text
    test('setFeedback updates feedback text', () async {
      final container = _makeContainer(_FakeRepo());
      addTearDown(container.dispose);

      container
          .read(confirmReceiptProvider(_kBatchId).notifier)
          .setFeedback('Great service');

      expect(
        container.read(confirmReceiptProvider(_kBatchId)).feedback,
        'Great service',
      );
    });

    // (6) submit sets isSubmitting=true then false on success
    test('submit sets isSubmitting=true then false on success', () async {
      final completer = Completer<void>();
      final pausingRepo = _PausingFakeRepo(completer);
      final pausingContainer = _makeContainer(pausingRepo);
      addTearDown(pausingContainer.dispose);

      // Keep auth provider alive and wait for it to emit.
      final authSub = await _waitForAuth(pausingContainer);
      addTearDown(authSub.close);

      // Also keep notifier alive.
      final notifierSub = pausingContainer.listen(
        confirmReceiptProvider(_kBatchId),
        (prev, next) {},
      );
      addTearDown(notifierSub.close);

      // Start submit — do NOT await yet.
      final submitFuture = pausingContainer
          .read(confirmReceiptProvider(_kBatchId).notifier)
          .submit();

      // Give the async work a chance to start.
      await Future<void>.microtask(() {});

      // isSubmitting should be true now.
      expect(
        pausingContainer.read(confirmReceiptProvider(_kBatchId)).isSubmitting,
        true,
      );

      // Allow the repo call to complete.
      completer.complete();
      await submitFuture;

      // isSubmitting should be false after completion.
      expect(
        pausingContainer.read(confirmReceiptProvider(_kBatchId)).isSubmitting,
        false,
      );
    });

    // (7) submit sets submitted=true on success
    test('submit sets submitted=true on success', () async {
      final container = _makeContainer(_FakeRepo());
      addTearDown(container.dispose);

      // Keep auth provider alive and wait for it to emit.
      final authSub = await _waitForAuth(container);
      addTearDown(authSub.close);

      // Keep notifier alive.
      final notifierSub = container.listen(
        confirmReceiptProvider(_kBatchId),
        (prev, next) {},
      );
      addTearDown(notifierSub.close);

      await container.read(confirmReceiptProvider(_kBatchId).notifier).submit();

      expect(container.read(confirmReceiptProvider(_kBatchId)).submitted, true);
    });

    // (8) submit sets error and re-enables button on repository exception
    test('submit sets error and isSubmitting=false on error', () async {
      final fakeRepo = _FakeRepo()..throwOnCall = Exception('network error');
      final container = _makeContainer(fakeRepo);
      addTearDown(container.dispose);

      // Keep auth provider alive and wait for it to emit.
      final authSub = await _waitForAuth(container);
      addTearDown(authSub.close);

      // Keep notifier alive.
      final notifierSub = container.listen(
        confirmReceiptProvider(_kBatchId),
        (prev, next) {},
      );
      addTearDown(notifierSub.close);

      await container.read(confirmReceiptProvider(_kBatchId).notifier).submit();

      final state = container.read(confirmReceiptProvider(_kBatchId));
      expect(state.error, isNotNull);
      expect(state.isSubmitting, false);
      expect(state.submitted, false);
    });

    // (9) double-submit guard: second call while isSubmitting returns immediately
    test(
      'double-submit guard: second call while in-flight does not call repo twice',
      () async {
        final completer = Completer<void>();
        final pausingRepo = _PausingFakeRepo(completer);
        final container = _makeContainer(pausingRepo);
        addTearDown(container.dispose);

        // Keep auth provider alive and wait for it to emit.
        final authSub = await _waitForAuth(container);
        addTearDown(authSub.close);

        // Keep notifier alive.
        final notifierSub = container.listen(
          confirmReceiptProvider(_kBatchId),
          (prev, next) {},
        );
        addTearDown(notifierSub.close);

        // Start first submit.
        final firstSubmit = container
            .read(confirmReceiptProvider(_kBatchId).notifier)
            .submit();

        await Future<void>.microtask(() {});

        // While isSubmitting is true, submit again.
        await container
            .read(confirmReceiptProvider(_kBatchId).notifier)
            .submit();

        // Complete the first.
        completer.complete();
        await firstSubmit;

        // Repo should only have been called once.
        expect(pausingRepo.callCount, 1);
      },
    );

    // (10) rating==0 passes rating: null to use case
    test('rating==0 passes rating: null to use case', () async {
      final fakeRepo = _FakeRepo();
      final container = _makeContainer(fakeRepo);
      addTearDown(container.dispose);

      // Keep auth provider alive and wait for it to emit.
      final authSub = await _waitForAuth(container);
      addTearDown(authSub.close);

      // Keep notifier alive.
      final notifierSub = container.listen(
        confirmReceiptProvider(_kBatchId),
        (prev, next) {},
      );
      addTearDown(notifierSub.close);

      // Do not set any rating (defaults to 0).
      await container.read(confirmReceiptProvider(_kBatchId).notifier).submit();

      expect(fakeRepo.capturedRating, isNull);
    });

    // (11) empty feedback passes feedback: null to use case
    test('empty feedback passes feedback: null to use case', () async {
      final fakeRepo = _FakeRepo();
      final container = _makeContainer(fakeRepo);
      addTearDown(container.dispose);

      // Keep auth provider alive and wait for it to emit.
      final authSub = await _waitForAuth(container);
      addTearDown(authSub.close);

      // Keep notifier alive.
      final notifierSub = container.listen(
        confirmReceiptProvider(_kBatchId),
        (prev, next) {},
      );
      addTearDown(notifierSub.close);

      // Do not set feedback (defaults to '').
      await container.read(confirmReceiptProvider(_kBatchId).notifier).submit();

      expect(fakeRepo.capturedFeedback, isNull);
    });
  });
}

/// A fake repo whose confirmReceipt suspends until the given completer resolves.
class _PausingFakeRepo extends _FakeRepo {
  _PausingFakeRepo(this._completer);
  final Completer<void> _completer;

  @override
  Future<void> confirmReceipt({
    required String batchId,
    required String beneficiaryId,
    int? rating,
    String? feedback,
  }) async {
    callCount++;
    await _completer.future;
    capturedBatchId = batchId;
    capturedBeneficiaryId = beneficiaryId;
    capturedRating = rating;
    capturedFeedback = feedback;
  }
}
