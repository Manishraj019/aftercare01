import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/core/router/app_router.dart';
import 'package:restaurantos/core/theme/app_theme.dart';

import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/menu_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/core/mocks/fake_repositories.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isFirebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization failed or skipped: $e');
    debugPrint('Continuing in offline/mock mode.');
  }

  runApp(
    ProviderScope(
      overrides: isFirebaseInitialized
          ? []
          : [
              authRemoteDataSourceProvider.overrideWithValue(FakeAuthRemoteDataSource()),
              menuRepositoryProvider.overrideWithValue(FakeMenuRepository()),
              cartRepositoryProvider.overrideWithValue(FakeCartRepository()),
              orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
            ],
      child: const RestaurantOSApp(),
    ),
  );
}

class RestaurantOSApp extends ConsumerWidget {
  const RestaurantOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RestaurantOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Respect system light/dark theme preference
      routerConfig: router,
    );
  }
}
