import 'package:dartz/dartz.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/auth/domain/entities/user_entity.dart';
import 'package:restaurantos/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) {
    return repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
