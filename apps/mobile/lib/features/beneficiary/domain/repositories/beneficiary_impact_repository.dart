// Pure Dart interface — no Flutter or backend imports.
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_impact.dart';

abstract class BeneficiaryImpactRepository {
  Stream<BeneficiaryImpact> watchImpact(String beneficiaryId);
}
