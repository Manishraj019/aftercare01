import 'package:dartz/dartz.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';

abstract class CartRepository {
  Future<Either<Failure, void>> syncCart(String userId, List<CartItemEntity> items);
  Future<Either<Failure, List<CartItemEntity>>> fetchCart(String userId);
}
