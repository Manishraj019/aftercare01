import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:restaurantos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:restaurantos/features/auth/domain/entities/user_entity.dart';
import 'package:restaurantos/features/auth/domain/repositories/auth_repository.dart';
import 'package:restaurantos/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:restaurantos/features/auth/domain/usecases/google_login_usecase.dart';
import 'package:restaurantos/features/auth/domain/usecases/login_usecase.dart';
import 'package:restaurantos/features/auth/domain/usecases/register_usecase.dart';
import 'package:restaurantos/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';

// Riverpod Providers for Data Source and Repository
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

// Riverpod Providers for Use Cases
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final googleLoginUseCaseProvider = Provider<GoogleLoginUseCase>((ref) {
  return GoogleLoginUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

// AuthViewModel StateNotifierProvider
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    googleLoginUseCase: ref.watch(googleLoginUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
    signOutUseCase: ref.watch(signOutUseCaseProvider),
  );
});

class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GoogleLoginUseCase _googleLoginUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SignOutUseCase _signOutUseCase;

  AuthViewModel({
    required this._loginUseCase,
    required this._registerUseCase,
    required this._googleLoginUseCase,
    required this._getCurrentUserUseCase,
    required this._signOutUseCase,
  })  : super(const AuthInitial()) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    state = const AuthLoading();
    try {
      final result = await _getCurrentUserUseCase();
      result.fold(
        (failure) {
          state = const Unauthenticated();
        },
        (user) {
          if (user != null) {
            state = Authenticated(user);
          } else {
            state = const Unauthenticated();
          }
        },
      );
    } catch (e) {
      state = const Unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    final result = await _loginUseCase(email: email, password: password);
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = Authenticated(user),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    state = const AuthLoading();
    final result = await _registerUseCase(
      name: name,
      email: email,
      password: password,
      role: role,
      phoneNumber: phoneNumber,
    );
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = Authenticated(user),
    );
  }

  Future<void> loginWithGoogle() async {
    state = const AuthLoading();
    final result = await _googleSignInHelper();
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = Authenticated(user),
    );
  }

  Future<void> logout() async {
    state = const AuthLoading();
    final result = await _signOutUseCase();
    result.fold(
      (failure) => state = AuthError(failure.message),
      (_) => state = const Unauthenticated(),
    );
  }

  void authenticateUser(UserEntity user) {
    state = Authenticated(user);
  }

  // Wrapper to isolate google sign-in call
  Future<dynamic> _googleSignInHelper() {
    return _googleLoginUseCase();
  }
}
