import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/beneficiary/presentation/providers/beneficiary_provider.dart';

part 'confirm_receipt_provider.g.dart';

class ConfirmReceiptState {
  const ConfirmReceiptState({
    this.rating = 0,
    this.feedback = '',
    this.isSubmitting = false,
    this.error,
    this.submitted = false,
  });

  final int rating;
  final String feedback;
  final bool isSubmitting;
  final String? error;
  final bool submitted;

  ConfirmReceiptState copyWith({
    int? rating,
    String? feedback,
    bool? isSubmitting,
    String? error,
    bool? submitted,
  }) => ConfirmReceiptState(
    rating: rating ?? this.rating,
    feedback: feedback ?? this.feedback,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: error,
    submitted: submitted ?? this.submitted,
  );
}

@riverpod
class ConfirmReceiptNotifier extends _$ConfirmReceiptNotifier {
  @override
  ConfirmReceiptState build(String batchId) => const ConfirmReceiptState();

  void setRating(int value) {
    if (value == state.rating) {
      state = state.copyWith(rating: 0);
    } else {
      state = state.copyWith(rating: value);
    }
  }

  void setFeedback(String value) {
    state = state.copyWith(feedback: value);
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true, error: null);

    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) {
      state = state.copyWith(isSubmitting: false, error: 'Not authenticated');
      return;
    }

    try {
      await ref
          .read(confirmReceiptUseCaseProvider)
          .call(
            batchId: batchId,
            beneficiaryId: uid,
            rating: state.rating == 0 ? null : state.rating,
            feedback: state.feedback.trim().isEmpty
                ? null
                : state.feedback.trim(),
          );
      state = state.copyWith(submitted: true, isSubmitting: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isSubmitting: false);
    }
  }
}
