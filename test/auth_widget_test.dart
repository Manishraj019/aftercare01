import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/core/localization/app_localizations.dart';
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
  testWidgets('Auth Flow Navigation Widget Test', (WidgetTester tester) async {
    // Build our app and override all Firebase dependencies to avoid SDK crashes
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

    // 1. Verify Splash Screen is shown initially
    expect(find.text('RestaurantOS'), findsOneWidget);

    // 2. Advance time (3s) to allow Splash Screen timer to complete and transition to Login Screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // 3. Verify Login Screen elements are loaded
    expect(find.text(AppLocalizations.loginTitle), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('signInButton')), findsOneWidget);

    // 4. Tap on "Sign Up" link to navigate to Register Screen
    final signUpLink = find.byKey(const Key('signUpLink'));
    await tester.ensureVisible(signUpLink);
    await tester.tap(signUpLink);
    await tester.pumpAndSettle();

    // 5. Verify Register Screen is shown (header and button both show 'Create Account')
    expect(find.text(AppLocalizations.registerTitle), findsNWidgets(2));

    // 6. Navigate back to Login Screen
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 7. Verify we are back on the Login Screen
    expect(find.text(AppLocalizations.loginTitle), findsOneWidget);
  });
}
