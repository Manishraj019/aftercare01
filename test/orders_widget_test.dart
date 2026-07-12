import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:restaurantos/features/auth/data/models/user_model.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';
import 'package:restaurantos/features/menu/domain/entities/menu_item_entity.dart';
import 'package:restaurantos/features/menu/domain/repositories/cart_repository.dart';
import 'package:restaurantos/features/menu/domain/repositories/menu_repository.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/menu_viewmodel.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/domain/entities/order_history_entry.dart';
import 'package:restaurantos/features/orders/domain/repositories/order_repository.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/main.dart';
import 'package:restaurantos/features/orders/domain/entities/dining_session.dart';

class FakeAuthRemoteDataSourceForOrders implements AuthRemoteDataSource {
  @override
  Future<UserModel> signInWithEmailAndPassword({required String email, required String password}) async {
    return _mockUser(email);
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    return _mockUser(email, role: role, name: name);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel?> getCurrentUser() async {
    return _mockUser('customer@restaurantos.com');
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    return _mockUser('google@restaurantos.com');
  }

  UserModel _mockUser(String email, {String role = 'customer', String name = 'Mock User'}) {
    return UserModel(
      uid: 'mock_customer_uid',
      name: name,
      email: email,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
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
  ];

  @override
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems(String restaurantId) async {
    return Right(_items);
  }

  @override
  Future<Either<Failure, MenuItemEntity>> getMenuItemDetails(String itemId) async {
    return Right(_items.firstWhere((item) => item.id == itemId));
  }
}

class FakeCartRepository implements CartRepository {
  List<CartItemEntity> _cart = [];

  @override
  Future<Either<Failure, List<CartItemEntity>>> fetchCart(String userId) async {
    return Right(_cart);
  }

  @override
  Future<Either<Failure, void>> syncCart(String userId, List<CartItemEntity> items) async {
    _cart = items;
    return const Right(null);
  }
}

class FakeOrderRepository implements OrderRepository {
  final List<OrderEntity> _orders = [];

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
    return const Right(null);
  }

  @override
  Future<Either<Failure, DiningSession>> getOrCreateActiveSession(
      String tableNumber, String restaurantId, String customerId, String customerName) async {
    return Right(DiningSession(
      sessionId: 'SID-FAKETEST',
      orderNumber: '#A1000',
      tableNumber: tableNumber,
      restaurantId: restaurantId,
      customerId: customerId,
      customerName: customerName,
      status: 'ordering',
      startTime: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, DiningSession?>> getActiveSessionForCustomer(String customerId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, DiningSession?>> getActiveSessionForTable(
      String tableNumber, String restaurantId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<DiningSession>>> getSessionsForOwner(String restaurantId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, OrderEntity>> appendItemsToSession(
    String sessionId, {
    required List newItems,
    required String modifiedBy,
    String? specialInstructions,
    double discount = 0.0,
    double coinDiscount = 0.0,
    double coinsRedeemed = 0.0,
  }) async {
    return Left(ServerFailure('Not implemented in fake'));
  }

  @override
  Future<Either<Failure, OrderEntity?>> getMasterOrderForSession(String sessionId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateKOTItemStatus(
      String orderId, String itemId, String status) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateKOTDetails(
      String orderId, {double? ownerDelay, String? priority}) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> freezeOrderForBilling(String sessionId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> closeSession(String sessionId,
      {required String paymentMethod,
      double discount = 0.0,
      double coinsRedeemed = 0.0,
      double coinsEarned = 0.0}) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<OrderHistoryEntry>>> getOrderHistoryForSession(String sessionId) async {
    return const Right([]);
  }

  @override
  String getKitchenLoadStatus() => 'Free';

  @override
  void setKitchenLoadStatus(String status) {}
}


void main() {
  testWidgets('Place Order and View Order History Integration Test', (WidgetTester tester) async {
    final fakeOrderRepo = FakeOrderRepository();

    // 1. Pump RestaurantOSApp with overridden data dependencies
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(FakeAuthRemoteDataSourceForOrders()),
          menuRepositoryProvider.overrideWithValue(FakeMenuRepository()),
          cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
          orderRepositoryProvider.overrideWithValue(fakeOrderRepo),
        ],
        child: const RestaurantOSApp(),
      ),
    );

    // Advance time past Splash screen auto-redirect
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Tap Scan Table QR Code to unlock MenuScreen
    final scanBtn = find.byKey(const Key('simulateQrScanButton'));
    expect(scanBtn, findsOneWidget);
    await tester.tap(scanBtn);
    await tester.pumpAndSettle();

    // 3. Add item to cart
    final addBtn = find.byKey(const Key('addBtn_menu_001'));
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // 4. View Cart
    final viewCartBtn = find.byKey(const Key('viewCartButton'));
    await tester.tap(viewCartBtn);
    await tester.pumpAndSettle();

    // 5. Click "Proceed to Checkout"
    final checkoutBtn = find.byKey(const Key('checkoutButton'));
    expect(checkoutBtn, findsOneWidget);
    await tester.tap(checkoutBtn);
    await tester.pumpAndSettle();

    // 6. Verify we are on Checkout Screen
    expect(find.text('Delivery Location'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);

    // Select Order Type: Delivery to bypass Dine In table number validation
    final deliveryTypeBtn = find.text('Delivery');
    expect(deliveryTypeBtn, findsOneWidget);
    await tester.tap(deliveryTypeBtn);
    await tester.pumpAndSettle();

    // 7. Select Payment Method: Card
    final payCardChip = find.byKey(const Key('pay_card'));
    expect(payCardChip, findsOneWidget);
    await tester.tap(payCardChip);
    await tester.pumpAndSettle();

    // 8. Place Order
    final confirmOrderBtn = find.byKey(const Key('confirmOrderButton'));
    expect(confirmOrderBtn, findsOneWidget);
    await tester.ensureVisible(confirmOrderBtn);
    await tester.pumpAndSettle();
    await tester.tap(confirmOrderBtn);
    await tester.pumpAndSettle();

    // 9. Verify redirect to Order History (assert 'My Orders' title and order exists in active list)
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('ACTIVE ORDERS'), findsOneWidget);
    expect(find.text('\$24.98'), findsOneWidget); // Subtotal: $18.50, Tax: $1.48, Delivery: $5.00 => Total: $24.98
    expect(find.text('1x Truffle Mushroom Fettuccine'), findsOneWidget);
  });
}
