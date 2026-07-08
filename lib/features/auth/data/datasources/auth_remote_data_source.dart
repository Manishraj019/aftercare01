import 'package:restaurantos/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Future<UserModel> signInWithGoogle();
}
