import 'package:dartz/dartz.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/auth/domain/entities/user_entity.dart';
import 'package:restaurantos/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, UserEntity?>> call() {
    return repository.getCurrentUser();
  }
}
