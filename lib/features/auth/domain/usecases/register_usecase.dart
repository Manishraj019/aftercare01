import 'package:dartz/dartz.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/auth/domain/entities/user_entity.dart';
import 'package:restaurantos/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) {
    return repository.registerWithEmailAndPassword(
      name: name,
      email: email,
      password: password,
      role: role,
      phoneNumber: phoneNumber,
    );
  }
}
