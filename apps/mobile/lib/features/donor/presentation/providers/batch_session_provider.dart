import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/donor/domain/entities/batch_item.dart';
import 'package:saveameal/features/donor/domain/entities/beneficiary.dart';

part 'batch_session_provider.g.dart';

@Riverpod(keepAlive: true)
class BatchSession extends _$BatchSession {
  @override
  List<BatchItem> build() => [];

  void add(BatchItem item) => state = [...state, item];

  void remove(int index) {
    final updated = [...state];
    updated.removeAt(index);
    state = updated;
  }

  void clear() => state = [];
}

/// Holds the beneficiary the donor optionally selected on the log-surplus form.
/// Null means "auto-assign at claim time".
@Riverpod(keepAlive: true)
class BatchBeneficiary extends _$BatchBeneficiary {
  @override
  Beneficiary? build() => null;

  void set(Beneficiary? beneficiary) => state = beneficiary;
  void clear() => state = null;
}
