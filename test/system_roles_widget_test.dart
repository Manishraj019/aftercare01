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
import 'package:restaurantos/features/menu/presentation/viewmodels/menu_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/domain/entities/order_history_entry.dart';
import 'package:restaurantos/features/orders/domain/repositories/order_repository.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/main.dart';
import 'package:restaurantos/features/orders/domain/entities/dining_session.dart';

class FakeAuthRemoteDataSourceForRole implements AuthRemoteDataSource {
  final String role;
  final String email;

  FakeAuthRemoteDataSourceForRole({required this.role, required this.email});

  @override
  Future<UserModel> signInWithEmailAndPassword({required String email, required String password}) async {
    return _mockUser();
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    return _mockUser();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel?> getCurrentUser() async {
    return _mockUser();
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    return _mockUser();
  }

  UserModel _mockUser() {
    return UserModel(
      uid: 'mock_role_uid',
      name: 'Test ${role.toUpperCase()}',
      email: email,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class FakeMenuRepository implements MenuRepository {
  final List<MenuItemEntity> _items = [
    const MenuItemEntity(
      id: 'menu_001',
      restaurantId: 'rest_456',
      name: 'Truffle Mushroom Fettuccine',
      description: 'Rich creamy sauce with wild forest mushrooms.',
      price: 18.50,
      category: 'Mains',
      isVegetarian: true,
      imageUrl: '',
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
  @override
  Future<Either<Failure, List<CartItemEntity>>> fetchCart(String userId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, void>> syncCart(String userId, List<CartItemEntity> items) async {
    return const Right(null);
  }
}

class FakeOrderRepository implements OrderRepository {
  @override
  Future<Either<Failure, void>> placeOrder(OrderEntity order) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getCustomerOrders(String customerId) async {
    return const Right([]);
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
  testWidgets('Super Admin Dashboard Verification', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(
            FakeAuthRemoteDataSourceForRole(role: 'admin', email: 'admin@restaurantos.com'),
          ),
          menuRepositoryProvider.overrideWithValue(FakeMenuRepository()),
          cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
          orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
        ],
        child: const RestaurantOSApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 1. Verify Super Admin Console routing
    expect(find.text('Super Admin Console'), findsOneWidget);
    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.text('Licensing'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);

    // 2. Open licensing tab and verify switches
    await tester.tap(find.text('Licensing'));
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsNWidgets(3));

    // 3. Register restaurant flow
    await tester.tap(find.text('Restaurants'));
    await tester.pumpAndSettle();
    
    final addBtn = find.byKey(const Key('addRestaurantButton'));
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('restNameField')), 'New Bistro');
    await tester.enterText(find.byKey(const Key('restAddrField')), '456 Main St');
    await tester.enterText(find.byKey(const Key('restCuisineField')), 'French');
    await tester.tap(find.byKey(const Key('saveRestButton')));
    await tester.pumpAndSettle();

    expect(find.text('New Bistro'), findsOneWidget);
  });

  testWidgets('Owner Dashboard Verification', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(
            FakeAuthRemoteDataSourceForRole(role: 'owner', email: 'owner@restaurantos.com'),
          ),
          menuRepositoryProvider.overrideWithValue(FakeMenuRepository()),
          cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
          orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
        ],
        child: const RestaurantOSApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 1. Verify Owner OS routing
    expect(find.text('Owner OS Dashboard'), findsOneWidget);
    expect(find.text('KDS Active'), findsOneWidget);
    expect(find.text('Menu Editor'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);

    // 2. Click Menu Editor & Add Item dialog flow
    await tester.tap(find.text('Menu Editor'));
    await tester.pumpAndSettle();

    final addMenuBtn = find.byKey(const Key('addMenuItemButton'));
    expect(addMenuBtn, findsOneWidget);
    await tester.tap(addMenuBtn);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('itemNameField')), 'Truffle Mac');
    await tester.enterText(find.byKey(const Key('itemPriceField')), '14.0');
    await tester.enterText(find.byKey(const Key('itemDescField')), 'Creamy mac cheese');
    await tester.tap(find.byKey(const Key('saveItemButton')));
    await tester.pumpAndSettle();

    expect(find.text('Truffle Mac'), findsOneWidget);
  });

  testWidgets('Customer Table Scan QR Flow Verification', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(
            FakeAuthRemoteDataSourceForRole(role: 'customer', email: 'customer@restaurantos.com'),
          ),
          menuRepositoryProvider.overrideWithValue(FakeMenuRepository()),
          cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
          orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
        ],
        child: const RestaurantOSApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 1. Verify Customer Landing scanning screen is shown
    expect(find.text('BistroOS Gateway'), findsOneWidget);
    expect(find.text('Scan Table QR Code'), findsOneWidget);

    // 2. Click scan simulation button
    final scanBtn = find.byKey(const Key('simulateQrScanButton'));
    expect(scanBtn, findsOneWidget);
    await tester.tap(scanBtn);
    await tester.pumpAndSettle();

    // 3. Verify it unlocks and navigates to the MenuScreen showing scanned table label
    expect(find.text('Gourmet Bistro (Table T-04)'), findsOneWidget);
  });
}
