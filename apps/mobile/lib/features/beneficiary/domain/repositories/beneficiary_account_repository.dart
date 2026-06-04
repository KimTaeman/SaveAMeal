// Pure Dart abstract interface — zero Flutter or backend imports.

import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_org_profile_update.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_profile.dart';
import 'package:saveameal/features/beneficiary/domain/entities/order_history_entry.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';

abstract class BeneficiaryAccountRepository {
  /// Emits the merged profile (users/{uid} + beneficiaries/{uid}) whenever either
  /// document changes. Emits null when the user document does not exist.
  /// joinedAt is derived from FirebaseAuth.currentUser.metadata.creationTime
  /// and passed through the datasource — the repository does not call Firebase Auth.
  Stream<BeneficiaryProfile?> watchProfile(String uid);

  /// Writes personal info fields to users/{uid}.
  /// Only non-null fields in [update] are written (merge semantics).
  Future<void> updatePersonalInfo(String uid, UserProfileUpdate update);

  /// Writes org profile fields to beneficiaries/{uid}.
  /// Only non-null fields in [update] are written (merge semantics).
  Future<void> updateOrgProfile(String uid, BeneficiaryOrgProfileUpdate update);

  /// Emits one page of delivered/closed batches for [uid],
  /// ordered by createdAt descending, page size [limit].
  /// Pass [cursor] (the ID of the last loaded entry) for cursor pagination
  /// (the datasource resolves this ID to a Firestore DocumentSnapshot internally).
  Stream<List<OrderHistoryEntry>> watchOrderHistory(
    String uid, {
    String? cursor,
    int limit = 10,
  });
}
