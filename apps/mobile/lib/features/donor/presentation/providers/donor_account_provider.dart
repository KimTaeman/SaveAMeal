import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/features/auth/presentation/providers/auth_provider.dart';
import 'package:saveameal/features/donor/data/datasources/donor_account_remote_datasource.dart';
import 'package:saveameal/features/donor/data/repositories/donor_account_repository_impl.dart';
import 'package:saveameal/features/donor/domain/repositories/donor_account_repository.dart';
import 'package:saveameal/features/donor/domain/usecases/update_user_usecase.dart';
import 'package:saveameal/services/service_providers.dart';

part 'donor_account_provider.g.dart';

@riverpod
DonorAccountRemoteDatasource donorAccountRemoteDatasource(Ref ref) =>
    DonorAccountRemoteDatasourceImpl(ref.watch(firestoreServiceProvider));

@riverpod
DonorAccountRepository donorAccountRepository(Ref ref) =>
    DonorAccountRepositoryImpl(ref.watch(donorAccountRemoteDatasourceProvider));

@riverpod
UpdateUserUsecase updateUserUsecase(Ref ref) =>
    UpdateUserUsecase(ref.watch(donorAccountRepositoryProvider));

@riverpod
Future<UserModel?> currentUser(Ref ref) async {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.asData?.value;
  if (user == null) return null;
  return ref.watch(donorAccountRepositoryProvider).getUser(user.uid);
}
