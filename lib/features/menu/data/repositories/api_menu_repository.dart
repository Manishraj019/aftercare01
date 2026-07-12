import 'package:dartz/dartz.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/menu/domain/entities/menu_item_entity.dart';
import 'package:restaurantos/features/menu/domain/repositories/menu_repository.dart';

class ApiMenuRepository implements MenuRepository {
  @override
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems(String restaurantId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Return mock data with high-quality Unsplash images
    return Right([
      MenuItemEntity(
        id: '1',
        restaurantId: restaurantId,
        name: 'Truffle Mushroom Risotto',
        description: 'Creamy arborio rice cooked with wild mushrooms and finished with truffle oil and parmesan.',
        price: 24.99,
        category: 'Mains',
        isVegetarian: true,
        imageUrl: 'https://images.unsplash.com/photo-1626200419109-d28224680749?q=80&w=800&auto=format&fit=crop',
        isBestSeller: true,
        preparationTimeMinutes: 12.0,
      ),
      MenuItemEntity(
        id: '2',
        restaurantId: restaurantId,
        name: 'Wagyu Beef Burger',
        description: 'Premium wagyu beef patty with caramelized onions, aged cheddar, and house sauce on a brioche bun.',
        price: 28.50,
        category: 'Mains',
        isVegetarian: false,
        imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=800&auto=format&fit=crop',
        isBestSeller: true,
        preparationTimeMinutes: 8.0,
      ),
      MenuItemEntity(
        id: '3',
        restaurantId: restaurantId,
        name: 'Spicy Tuna Tartare',
        description: 'Fresh sashimi-grade tuna mixed with spicy mayo, avocado, and served with crispy wonton chips.',
        price: 18.00,
        category: 'Starters',
        isVegetarian: false,
        imageUrl: 'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?q=80&w=800&auto=format&fit=crop',
        preparationTimeMinutes: 10.0,
      ),
      MenuItemEntity(
        id: '4',
        restaurantId: restaurantId,
        name: 'Classic Margherita Pizza',
        description: 'Wood-fired pizza with San Marzano tomato sauce, fresh mozzarella, and basil.',
        price: 16.00,
        category: 'Mains',
        isVegetarian: true,
        imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?q=80&w=800&auto=format&fit=crop',
        preparationTimeMinutes: 15.0,
      ),
      MenuItemEntity(
        id: '5',
        restaurantId: restaurantId,
        name: 'Matcha Lava Cake',
        description: 'Warm matcha green tea cake with a gooey center, served with vanilla bean ice cream.',
        price: 12.50,
        category: 'Desserts',
        isVegetarian: true,
        imageUrl: 'https://images.unsplash.com/photo-1515037025445-5d43cb80f8eb?q=80&w=800&auto=format&fit=crop',
        preparationTimeMinutes: 10.0,
      ),
      MenuItemEntity(
        id: '6',
        restaurantId: restaurantId,
        name: 'Signature Cocktails',
        description: 'A selection of our finest handcrafted cocktails.',
        price: 14.00,
        category: 'Beverages',
        isVegetarian: true,
        imageUrl: 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?q=80&w=800&auto=format&fit=crop',
        preparationTimeMinutes: 2.0,
      ),
    ]);
  }

  @override
  Future<Either<Failure, MenuItemEntity>> getMenuItemDetails(String itemId) async {
    return Left(ServerFailure('Not implemented in mock'));
  }
}
