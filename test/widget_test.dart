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

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return UserModel(
      uid: 'mock_uid_123',
      name: 'Mock User',
      email: email,
      role: 'customer',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    return UserModel(
      uid: 'mock_uid_123',
      name: name,
      email: email,
      role: role,
      phoneNumber: phoneNumber,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel> signInWithGoogle() async {
    return UserModel(
      uid: 'mock_google_123',
      name: 'Google Mock',
      email: 'google@mock.com',
      role: 'customer',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class FakeMenuRepository implements MenuRepository {
  @override
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems(String restaurantId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, MenuItemEntity>> getMenuItemDetails(String itemId) async {
    return Left(ServerFailure('Not implemented in mock'));
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

void main() {
  testWidgets('Splash Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame, overriding all Firebase dependencies
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(FakeAuthRemoteDataSource()),
          menuRepositoryProvider.overrideWithValue(FakeMenuRepository()),
          cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
        ],
        child: const RestaurantOSApp(),
      ),
    );

    // Verify that the splash screen shows 'RestaurantOS'.
    expect(find.text('RestaurantOS'), findsOneWidget);

    // Verify that a progress indicator is present.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    // Advance time to allow the splash screen's redirect timer (2s) to fire and complete.
    await tester.pump(const Duration(seconds: 3));
  });
}
