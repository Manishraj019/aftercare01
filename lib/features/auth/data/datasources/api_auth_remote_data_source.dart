import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:restaurantos/features/auth/data/models/user_model.dart';
import 'package:restaurantos/features/auth/data/datasources/auth_remote_data_source.dart';

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserModel.fromJson(json['user']);
    } else {
      throw Exception('Failed to sign in: ${response.statusCode}');
    }
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserModel.fromJson(json['user']);
    } else {
      throw Exception('Failed to register: ${response.statusCode}');
    }
  }

  @override
  Future<void> signOut() async {
    // In a stateless JWT REST API, sign out is usually handled by clearing tokens locally.
    // If your backend requires invalidating a token, make an API call here.
    return;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    // In a real app, you would retrieve the JWT from secure storage, and send a GET /auth/me request.
    // For now, this returns null to simulate unauthenticated initial state.
    return null; 
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    throw UnimplementedError('Google sign-in via custom API not implemented yet');
  }
}
