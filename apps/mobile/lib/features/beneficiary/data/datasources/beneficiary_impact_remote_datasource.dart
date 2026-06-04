import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saveameal/features/beneficiary/data/models/beneficiary_impact_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';

abstract class BeneficiaryImpactRemoteDatasource {
  /// Streams impactMetrics/{beneficiaryId}.
  /// Emits [BeneficiaryImpact.empty] when the document does not yet exist.
  Stream<BeneficiaryImpact> watchImpact(String beneficiaryId);
}

class BeneficiaryImpactRemoteDatasourceImpl
    implements BeneficiaryImpactRemoteDatasource {
  const BeneficiaryImpactRemoteDatasourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<BeneficiaryImpact> watchImpact(String beneficiaryId) {
    return _firestore
        .collection('impactMetrics')
        .doc(beneficiaryId)
        .snapshots()
        .map(
          (ds) => ds.exists && ds.data() != null
              ? BeneficiaryImpactModel.fromFirestore(ds.data()!).toEntity()
              : BeneficiaryImpact.empty,
        );
  }
}
