import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:saveameal/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:saveameal/features/auth/domain/entities/app_user.dart';
import 'package:saveameal/features/auth/domain/repositories/auth_repository.dart';
import 'package:saveameal/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:saveameal/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:saveameal/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:saveameal/services/service_providers.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRemoteDatasource authDatasource(Ref ref) => AuthRemoteDatasourceImpl(
  ref.watch(authServiceProvider),
  ref.watch(firestoreServiceProvider),
);

@riverpod
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(authDatasourceProvider));

@riverpod
Stream<AppUser?> authState(Ref ref) =>
    ref.watch(authRepositoryProvider).watchAuthState();

@riverpod
SignInUsecase signInUsecase(Ref ref) =>
    SignInUsecase(ref.watch(authRepositoryProvider));

@riverpod
SignUpUsecase signUpUsecase(Ref ref) =>
    SignUpUsecase(ref.watch(authRepositoryProvider));

@riverpod
SignOutUsecase signOutUsecase(Ref ref) =>
    SignOutUsecase(ref.watch(authRepositoryProvider));
