// Pure Dart use case — zero Flutter or backend imports.
import 'package:saveameal/features/donor/domain/repositories/donor_account_repository.dart';

class UpdateUserUsecase {
  const UpdateUserUsecase(this._repository);

  final DonorAccountRepository _repository;

  Future<void> call(String uid, Map<String, dynamic> fields) =>
      _repository.updateUser(uid, fields);
}
