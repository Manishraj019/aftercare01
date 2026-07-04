import 'package:dartz/dartz.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:restaurantos/features/auth/data/models/user_model.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';
import 'package:restaurantos/features/menu/domain/entities/menu_item_entity.dart';
import 'package:restaurantos/features/menu/domain/repositories/cart_repository.dart';
import 'package:restaurantos/features/menu/domain/repositories/menu_repository.dart';
import 'package:restaurantos/features/owner/presentation/widgets/fake_owner_data.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/domain/repositories/order_repository.dart';

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  UserModel? _currentUser;

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    String role = 'customer';
    String name = 'Gourmet Lover';

    try {
      final matchingShop = FakeOwnerData.virtualShops.firstWhere(
        (shop) => shop.email.toLowerCase() == email.toLowerCase() && shop.password == password,
      );
      role = 'owner';
      name = matchingShop.shopName;
    } catch (_) {
      if (email.toLowerCase().contains('owner')) {
        role = 'owner';
        name = 'Alessandro Russo';
      } else if (email.toLowerCase().contains('admin')) {
        role = 'admin';
        name = 'Super Administrator';
      }
    }

    final user = UserModel(
      uid: 'mock_${role}_123',
      name: name,
      email: email,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _currentUser = user;
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
    final user = UserModel(
      uid: 'mock_user_123',
      name: name,
      email: email,
      role: role,
      phoneNumber: phoneNumber,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (role == 'owner') {
      // Register new virtual shop in database
      FakeOwnerData.virtualShops.add(VirtualShop(
        shopId: 'SHOP-${(FakeOwnerData.virtualShops.length + 1).toString().padLeft(3, '0')}',
        shopName: name,
        email: email,
        password: password,
        tableCapacity: 8,
        staffQuantity: 5,
      ));
    }

    _currentUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final user = UserModel(
      uid: 'mock_google_123',
      name: 'Google User',
      email: 'google@restaurantos.com',
      role: 'customer',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _currentUser = user;
    return user;
  }
}

class FakeMenuRepository implements MenuRepository {
  static final List<MenuItemEntity> _items = [
    const MenuItemEntity(
      id: 'menu_001',
      restaurantId: 'rest_456',
      name: 'Truffle Mushroom Fettuccine',
      description: 'Rich creamy sauce with wild forest mushrooms, finished with aromatic black truffle oil.',
      price: 18.50,
      category: 'Mains',
      isVegetarian: true,
      imageUrl: 'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?auto=format&fit=crop&w=400&q=80',
    ),
    const MenuItemEntity(
      id: 'menu_002',
      restaurantId: 'rest_456',
      name: 'Wood-Fired Pepperoni Pizza',
      description: 'Spicy pepperoni slices, fresh mozzarella, fresh basil, and signature marinara sauce.',
      price: 16.00,
      category: 'Mains',
      isVegetarian: false,
      imageUrl: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80',
    ),
    const MenuItemEntity(
      id: 'menu_003',
      restaurantId: 'rest_456',
      name: 'Crispy Calamari Rings',
      description: 'Golden fried seasoned calamari rings served with house lemon garlic aioli dip.',
      price: 12.00,
      category: 'Appetizers',
      isVegetarian: false,
      imageUrl: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&w=400&q=80',
    ),
    const MenuItemEntity(
      id: 'menu_004',
      restaurantId: 'rest_456',
      name: 'Molten Chocolate Lava Cake',
      description: 'Rich chocolate cake with a warm flowing center, served with vanilla bean ice cream.',
      price: 8.50,
      category: 'Desserts',
      isVegetarian: true,
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=400&q=80',
    ),
    const MenuItemEntity(
      id: 'menu_005',
      restaurantId: 'rest_456',
      name: 'Fresh Mint Lime Mojito',
      description: 'Zesty lime, fresh mint leaves, cane sugar syrup, and soda served over crushed ice.',
      price: 6.00,
      category: 'Beverages',
      isVegetarian: true,
      imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=400&q=80',
    ),
  ];

  @override
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems(String restaurantId) async {
    return Right(_items);
  }

  @override
  Future<Either<Failure, MenuItemEntity>> getMenuItemDetails(String itemId) async {
    try {
      final item = _items.firstWhere((item) => item.id == itemId);
      return Right(item);
    } catch (_) {
      return Left(ServerFailure('Menu item not found'));
    }
  }
}

class FakeCartRepository implements CartRepository {
  final Map<String, List<CartItemEntity>> _userCarts = {};

  @override
  Future<Either<Failure, List<CartItemEntity>>> fetchCart(String userId) async {
    return Right(_userCarts[userId] ?? []);
  }

  @override
  Future<Either<Failure, void>> syncCart(String userId, List<CartItemEntity> items) async {
    _userCarts[userId] = items;
    return const Right(null);
  }
}

class FakeOrderRepository implements OrderRepository {
  final List<OrderEntity> _orders = [
    // Pre-populate one past order so history looks nice out-of-the-box
    OrderEntity(
      id: 'ord_mock_101',
      customerId: 'mock_user_123',
      restaurantId: 'rest_456',
      items: const [
        CartItemEntity(
          itemId: 'menu_002',
          name: 'Wood-Fired Pepperoni Pizza',
          price: 16.00,
          quantity: 1,
          imageUrl: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80',
        ),
        CartItemEntity(
          itemId: 'menu_005',
          name: 'Fresh Mint Lime Mojito',
          price: 6.00,
          quantity: 1,
          imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=400&q=80',
        ),
      ],
      subtotal: 22.00,
      tax: 1.76,
      deliveryFee: 5.00,
      total: 28.76,
      status: 'delivered',
      deliveryAddress: '123 Gourmet Ave, Foodtown',
      paymentMethod: 'card',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<Either<Failure, void>> placeOrder(OrderEntity order) async {
    _orders.insert(0, order);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getCustomerOrders(String customerId) async {
    return Right(_orders);
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(String orderId, String status) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      final existing = _orders[idx];
      _orders[idx] = OrderEntity(
        id: existing.id,
        customerId: existing.customerId,
        restaurantId: existing.restaurantId,
        items: existing.items,
        subtotal: existing.subtotal,
        tax: existing.tax,
        deliveryFee: existing.deliveryFee,
        discount: existing.discount,
        total: existing.total,
        status: status,
        deliveryAddress: existing.deliveryAddress,
        paymentMethod: existing.paymentMethod,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );
    }
    return const Right(null);
  }
}
