import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:restaurantos/features/auth/data/models/user_model.dart';
import 'package:restaurantos/features/auth/data/datasources/auth_remote_data_source.dart';

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  static UserModel? _mockPersistentUser;

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Mock login for demo purposes
    await Future.delayed(const Duration(milliseconds: 300)); // simulate network delay
    String role = 'Customer';
    if (email.contains('admin') || email.contains('staff')) role = 'Admin';
    if (email.contains('owner') || email.contains('hotel')) role = 'Hotel';
    if (email.contains('chef')) role = 'Chef';
    if (email.contains('waiter') || email.contains('inventory')) role = 'Waiter';

    final user = UserModel(
      uid: 'demo_user_123',
      name: 'Demo User',
      email: email,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _mockPersistentUser = user;
    return user;
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    // Mock register for demo purposes
    await Future.delayed(const Duration(milliseconds: 300)); // simulate network delay
    final user = UserModel(
      uid: 'demo_user_new',
      name: name,
      email: email,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _mockPersistentUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    // In a stateless JWT REST API, sign out is usually handled by clearing tokens locally.
    // If your backend requires invalidating a token, make an API call here.
    _mockPersistentUser = null;
    return;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // In a real app, you would retrieve the JWT from secure storage, and send a GET /auth/me request.
    // For now, this returns the simulated authenticated state from memory.
    return _mockPersistentUser; 
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    throw UnimplementedError('Google sign-in via custom API not implemented yet');
  }
}
