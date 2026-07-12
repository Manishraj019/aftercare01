import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurantos/features/auth/data/models/user_model.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/loyalty/presentation/screens/wallet_screen.dart';
import 'package:restaurantos/features/loyalty/presentation/screens/reward_store_screen.dart';
import 'package:restaurantos/features/loyalty/presentation/viewmodels/loyalty_viewmodel.dart';
import 'package:restaurantos/features/loyalty/data/repositories/loyalty_repository.dart';

class MockAuthViewModel extends StateNotifier<AuthState> implements AuthViewModel {
  MockAuthViewModel(super.state);

  @override
  Future<void> checkCurrentUser() async {}

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {}

  @override
  Future<void> loginWithGoogle() async {}

  @override
  Future<void> logout() async {}

  @override
  void authenticateUser(dynamic user) {}
}

void main() {
  late UserModel fakeUser;

  setUp(() {
    // Reset configuration and mock data in LoyaltyRepository for test isolation
    LoyaltyRepository.config = const LoyaltyConfig(
      welcomeBonus: 50.0,
      earnRate: 10.0,
      redeemRate: 10.0,
      goldThreshold: 200.0,
      platinumThreshold: 500.0,
    );
    LoyaltyRepository.resetMockData();

    fakeUser = UserModel(
      uid: 'mock_customer_uid',
      name: 'Mock Customer',
      email: 'customer@restaurantos.com',
      role: 'customer',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith((ref) => MockAuthViewModel(Authenticated(fakeUser))),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('Wallet Screen displays balance, tier, and transaction history correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const WalletScreen()));
    await tester.pumpAndSettle();

    // Verify current balance is displayed (mock data has 150 balance)
    expect(find.text('150'), findsOneWidget);
    expect(find.text('CURRENT BALANCE'), findsOneWidget);

    // Verify membership level Silver is displayed
    expect(find.text('SILVER'), findsOneWidget);

    // Verify list item (Welcome Bonus Reward is in history)
    expect(find.text('Welcome Bonus Reward'), findsOneWidget);
    expect(find.text('Account Setup & Profile Completion'), findsOneWidget);
  });

  testWidgets('Wallet Screen claims daily check-in successfully', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const WalletScreen()));
    await tester.pumpAndSettle();

    // Verify initial balance
    expect(find.text('150'), findsOneWidget);

    // Tap Daily Check-In button
    final checkinButton = find.byKey(const Key('dailyCheckinButton'));
    expect(checkinButton, findsOneWidget);
    await tester.tap(checkinButton);
    await tester.pumpAndSettle();

    // Verify updated balance (150 welcome/initial + 10 check-in = 160)
    expect(find.text('160'), findsOneWidget);
    expect(find.text('Daily Check-In Reward'), findsOneWidget);
  });

  testWidgets('Reward Store Screen displays and claims active offers', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(const RewardStoreScreen()));
    await tester.pumpAndSettle();

    // Verify balances in header (initial 150)
    expect(find.text('150'), findsOneWidget);

    // Verify offer elements
    expect(find.text('Free Fresh Mint Lime Mojito'), findsOneWidget);
    expect(find.text('60 Coins'), findsOneWidget);

    // Tap "CLAIM OFFER" on Mojito
    final claimButton = find.byKey(const Key('claim_offer_bev_01'));
    expect(claimButton, findsOneWidget);
    await tester.tap(claimButton);
    await tester.pumpAndSettle();

    // Click confirm in the AlertDialog
    final confirmButton = find.byKey(const Key('confirmClaimButton'));
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    // Verify success unlocked dialog pops up with the code
    expect(find.text('Reward Unlocked!'), findsOneWidget);
    expect(find.text('MOJITO60'), findsOneWidget);
  });
}
