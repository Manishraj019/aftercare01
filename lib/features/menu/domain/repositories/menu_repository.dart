import 'package:dartz/dartz.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/menu/domain/entities/menu_item_entity.dart';

abstract class MenuRepository {
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems(String restaurantId);
  Future<Either<Failure, MenuItemEntity>> getMenuItemDetails(String itemId);
}
