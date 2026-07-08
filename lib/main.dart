import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/core/router/app_router.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/menu_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:restaurantos/features/auth/data/datasources/api_auth_remote_data_source.dart';
import 'package:restaurantos/features/menu/data/repositories/api_menu_repository.dart';
import 'package:restaurantos/features/menu/data/repositories/api_cart_repository.dart';
import 'package:restaurantos/features/orders/data/repositories/api_order_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        authRemoteDataSourceProvider.overrideWithValue(ApiAuthRemoteDataSource()),
        menuRepositoryProvider.overrideWithValue(ApiMenuRepository()),
        cartRepositoryProvider.overrideWithValue(ApiCartRepository()),
        orderRepositoryProvider.overrideWithValue(ApiOrderRepository()),
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
      theme: AppTheme.luxuryTheme,
      darkTheme: AppTheme.luxuryTheme,
      themeMode: ThemeMode.dark,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      ),
      routerConfig: router,
    );
  }
}
