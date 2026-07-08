import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/menu/domain/entities/menu_item_entity.dart';
import 'package:restaurantos/features/menu/domain/repositories/menu_repository.dart';

class ApiMenuRepository implements MenuRepository {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  @override
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems(String restaurantId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menu/$restaurantId'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final items = jsonList.map((json) => MenuItemEntity(
          id: json['id'],
          restaurantId: json['restaurantId'],
          name: json['name'],
          description: json['description'],
          price: json['price'].toDouble(),
          category: json['category'],
          isVegetarian: json['isVegetarian'],
          imageUrl: json['imageUrl'],
        )).toList();
        return Right(items);
      } else {
        return Left(ServerFailure('Failed to load menu: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MenuItemEntity>> getMenuItemDetails(String itemId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/menu/item/$itemId'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final item = MenuItemEntity(
          id: json['id'],
          restaurantId: json['restaurantId'],
          name: json['name'],
          description: json['description'],
          price: json['price'].toDouble(),
          category: json['category'],
          isVegetarian: json['isVegetarian'],
          imageUrl: json['imageUrl'],
        );
        return Right(item);
      } else {
        return Left(ServerFailure('Failed to load menu item: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
