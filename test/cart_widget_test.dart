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
import 'package:restaurantos/main.dart';

class FakeAuthRemoteDataSourceForCart implements AuthRemoteDataSource {
  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
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
    try {
      final item = _items.firstWhere((item) => item.id == itemId);
      return Right(item);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
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

void main() {
  testWidgets('Cart and Billing Operations Test', (WidgetTester tester) async {
    // 1. Pump the RestaurantOSApp with our mock remote data source and repositories overridden
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(FakeAuthRemoteDataSourceForCart()),
          menuRepositoryProvider.overrideWithValue(FakeMenuRepository()),
          cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
        ],
        child: const RestaurantOSApp(),
      ),
    );

    // 2. Wait for Splash Screen redirect timer (2s) to complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Tap Scan Table QR Code to unlock MenuScreen
    final scanBtn = find.byKey(const Key('simulateQrScanButton'));
    expect(scanBtn, findsOneWidget);
    await tester.tap(scanBtn);
    await tester.pumpAndSettle();

    // 3. Verify we auto-logged in and redirected directly to the MenuScreen
    expect(find.text('Gourmet Bistro (Table T-04)'), findsOneWidget);
    expect(find.text('Truffle Mushroom Fettuccine'), findsOneWidget);

    // 4. Verify cart is initially empty (shopping bag icon doesn't show badge)
    expect(find.text('1 Items in bag'), findsNothing);

    // 5. Add "Truffle Mushroom Fettuccine" to cart (Item price is $18.50)
    final addTruffleBtn = find.byKey(const Key('addBtn_menu_001'));
    expect(addTruffleBtn, findsOneWidget);
    await tester.tap(addTruffleBtn);
    await tester.pumpAndSettle();

    // 6. Verify sticky bottom cart bar is visible with 1 item
    expect(find.text('1 Items in bag'), findsOneWidget);
    expect(find.text('Total \$18.50'), findsOneWidget);

    // 7. Tap "View Cart" to navigate to the CartScreen
    final viewCartBtn = find.byKey(const Key('viewCartButton'));
    expect(viewCartBtn, findsOneWidget);
    await tester.tap(viewCartBtn);
    await tester.pumpAndSettle();

    // 8. Verify CartScreen is shown with items and billing breakdown
    expect(find.text('Your Order'), findsOneWidget);
    expect(find.text('Truffle Mushroom Fettuccine'), findsOneWidget);
    expect(find.text('\$18.50 each'), findsOneWidget);
    expect(find.text('\$18.50'), findsNWidgets(2)); // Subtotal & Item total

    // 9. Increment quantity to 2
    final incBtn = find.byKey(const Key('inc_menu_001'));
    expect(incBtn, findsOneWidget);
    await tester.tap(incBtn);
    await tester.pumpAndSettle();

    // 10. Verify quantity and billing calculation update:
    // Subtotal: 2 * $18.50 = $37.00
    // Tax (8%): 0.08 * $37.00 = $2.96
    // Delivery Fee: $5.00
    // Grand Total: $37.00 + $2.96 + $5.00 = $44.96
    expect(find.text('2'), findsOneWidget);
    expect(find.text('\$37.00'), findsNWidgets(2)); // Subtotal & Item total
    expect(find.text('\$2.96'), findsOneWidget); // Tax
    expect(find.text('\$5.00'), findsOneWidget); // Delivery Fee
    expect(find.text('\$44.96'), findsOneWidget); // Grand Total

    // 11. Perform checkout redirect
    final checkoutBtn = find.byKey(const Key('checkoutButton'));
    expect(checkoutBtn, findsOneWidget);
    await tester.tap(checkoutBtn);
    await tester.pumpAndSettle();

    // 12. Verify we transitioned to CheckoutScreen
    expect(find.text('Delivery Location'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);
  });
}
