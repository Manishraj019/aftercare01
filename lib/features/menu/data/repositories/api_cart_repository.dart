import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';
import 'package:restaurantos/features/menu/domain/repositories/cart_repository.dart';

class ApiCartRepository implements CartRepository {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  @override
  Future<Either<Failure, void>> syncCart(String userId, List<CartItemEntity> items) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/sync/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'items': items.map((e) => {
            'menuItemId': e.itemId,
            'quantity': e.quantity,
          }).toList(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(null);
      } else {
        return Left(ServerFailure('Failed to sync cart: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> fetchCart(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cart/$userId'));
      
      if (response.statusCode == 200) {
        // Needs a robust backend implementation to return full menu item details inside cart items.
        // For now, parsing an empty list if backend is not fully implemented.
        return const Right([]); 
      } else {
        return Left(ServerFailure('Failed to fetch cart: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
