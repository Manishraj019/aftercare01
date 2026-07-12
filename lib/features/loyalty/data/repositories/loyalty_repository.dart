import 'package:flutter/foundation.dart';
import 'package:restaurantos/features/loyalty/domain/entities/wallet_entity.dart';
import 'package:restaurantos/features/loyalty/domain/entities/reward_offer_entity.dart';

class LoyaltyCampaign {
  final String id;
  final String name;
  final String description;
  final double multiplier;
  final bool isActive;

  const LoyaltyCampaign({
    required this.id,
    required this.name,
    required this.description,
    required this.multiplier,
    required this.isActive,
  });
}

class LoyaltyConfig {
  final double welcomeBonus;
  final double earnRate; // dollars per 1 coin (e.g. 10.0 means 1 coin per $10 spent)
  final double redeemRate; // coins per $1 discount (e.g. 10.0 means 10 coins = $1)
  final double goldThreshold;
  final double platinumThreshold;

  const LoyaltyConfig({
    required this.welcomeBonus,
    required this.earnRate,
    required this.redeemRate,
    required this.goldThreshold,
    required this.platinumThreshold,
  });

  LoyaltyConfig copyWith({
    double? welcomeBonus,
    double? earnRate,
    double? redeemRate,
    double? goldThreshold,
    double? platinumThreshold,
  }) {
    return LoyaltyConfig(
      welcomeBonus: welcomeBonus ?? this.welcomeBonus,
      earnRate: earnRate ?? this.earnRate,
      redeemRate: redeemRate ?? this.redeemRate,
      goldThreshold: goldThreshold ?? this.goldThreshold,
      platinumThreshold: platinumThreshold ?? this.platinumThreshold,
    );
  }
}

class LoyaltyRepository {
  static final List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback l) => _listeners.add(l);
  static void removeListener(VoidCallback l) => _listeners.remove(l);
  static void notifyListeners() {
    for (final l in _listeners) {
      try {
        l();
      } catch (_) {}
    }
  }

  // Global Config
  static LoyaltyConfig config = const LoyaltyConfig(
    welcomeBonus: 50.0,
    earnRate: 10.0,   // 1 coin per $10 spent
    redeemRate: 10.0, // 10 coins = $1 discount
    goldThreshold: 200.0,
    platinumThreshold: 500.0,
  );

  static void resetMockData() {
    _wallets.clear();
    _wallets['mock_customer_uid'] = const WalletEntity(
      id: 'w_customer_01',
      customerId: 'mock_customer_uid',
      balance: 150.0,
      lifetimeEarned: 220.0,
      totalRedeemed: 70.0,
      membershipLevel: 'Silver',
    );

    _transactions.clear();
    _transactions['mock_customer_uid'] = [
      WalletTransaction(
        id: 'tx_01',
        amount: 50.0,
        type: 'bonus',
        description: 'Welcome Bonus Reward',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      WalletTransaction(
        id: 'tx_02',
        amount: 70.0,
        type: 'earn',
        description: 'Earned from Dine-In Order #9F21A',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        restaurantName: 'Gourmet Bistro',
        orderId: 'ord_mock_101',
      ),
      WalletTransaction(
        id: 'tx_03',
        amount: 70.0,
        type: 'redeem',
        description: 'Redeemed for FREE beverage coupon',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      WalletTransaction(
        id: 'tx_04',
        amount: 100.0,
        type: 'bonus',
        description: 'Account Setup & Profile Completion',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  // In-Memory Wallets
  static final Map<String, WalletEntity> _wallets = {
    'mock_customer_uid': const WalletEntity(
      id: 'w_customer_01',
      customerId: 'mock_customer_uid',
      balance: 150.0,
      lifetimeEarned: 220.0,
      totalRedeemed: 70.0,
      membershipLevel: 'Silver',
    ),
  };

  // In-Memory Transactions
  static final Map<String, List<WalletTransaction>> _transactions = {
    'mock_customer_uid': [
      WalletTransaction(
        id: 'tx_01',
        amount: 50.0,
        type: 'bonus',
        description: 'Welcome Bonus Reward',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      WalletTransaction(
        id: 'tx_02',
        amount: 70.0,
        type: 'earn',
        description: 'Earned from Dine-In Order #9F21A',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        restaurantName: 'Gourmet Bistro',
        orderId: 'ord_mock_101',
      ),
      WalletTransaction(
        id: 'tx_03',
        amount: 70.0,
        type: 'redeem',
        description: 'Redeemed for FREE beverage coupon',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      WalletTransaction(
        id: 'tx_04',
        amount: 100.0,
        type: 'bonus',
        description: 'Account Setup & Profile Completion',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ],
  };

  // In-Memory Reward Store Offers
  static final List<RewardOfferEntity> rewardOffers = [
    const RewardOfferEntity(
      id: 'offer_bev_01',
      title: 'Free Fresh Mint Lime Mojito',
      description: 'Exchange 60 SuperCoins for a refreshing mint lime mojito on your next visit.',
      costInCoins: 60,
      category: 'beverage',
      imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=400&q=80',
      isActive: true,
      promoCode: 'MOJITO60',
    ),
    const RewardOfferEntity(
      id: 'offer_des_01',
      title: 'Molten Chocolate Lava Cake',
      description: 'Exchange 85 SuperCoins to unlock a decadent molten lava cake with vanilla gelato.',
      costInCoins: 85,
      category: 'dessert',
      imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=400&q=80',
      isActive: true,
      promoCode: 'LAVACAKE85',
    ),
    const RewardOfferEntity(
      id: 'offer_coup_01',
      title: '\$15 Off Coupon code',
      description: 'Exchange 150 SuperCoins to claim a flat \$15 discount coupon on bills over \$50.',
      costInCoins: 150,
      category: 'discount',
      imageUrl: 'https://images.unsplash.com/photo-1629812456605-4a044aa38fbc?auto=format&fit=crop&w=400&q=80',
      isActive: true,
      promoCode: 'LOYAL15',
    ),
    const RewardOfferEntity(
      id: 'offer_bev_02',
      title: 'Premium Italian Espresso',
      description: 'Exchange 40 SuperCoins for a rich and double espresso shot made with custom roasted beans.',
      costInCoins: 40,
      category: 'beverage',
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=400&q=80',
      isActive: true,
      promoCode: 'ESPRESSO40',
    ),
  ];

  // In-Memory Promotional Campaigns
  static final List<LoyaltyCampaign> campaigns = [
    const LoyaltyCampaign(
      id: 'camp_01',
      name: '2x SuperCoins Weekend',
      description: 'Earn double rewards on all orders placed during Saturday and Sunday!',
      multiplier: 2.0,
      isActive: true,
    ),
    const LoyaltyCampaign(
      id: 'camp_02',
      name: 'Festival of Lights Special',
      description: 'Earn 3x loyalty points on all dine-in reservations.',
      multiplier: 3.0,
      isActive: false,
    ),
  ];

  // Fetch Wallet details
  WalletEntity getOrCreateWallet(String customerId) {
    if (!_wallets.containsKey(customerId)) {
      _wallets[customerId] = WalletEntity(
        id: 'w_${customerId.substring(0, min(5, customerId.length))}',
        customerId: customerId,
        balance: config.welcomeBonus,
        lifetimeEarned: config.welcomeBonus,
        totalRedeemed: 0.0,
        membershipLevel: 'Silver',
      );
      
      // Welcome Transaction
      _transactions[customerId] = [
        WalletTransaction(
          id: 'tx_welcome_${DateTime.now().millisecondsSinceEpoch}',
          amount: config.welcomeBonus,
          type: 'bonus',
          description: 'Welcome Registration Bonus',
          createdAt: DateTime.now(),
        ),
      ];
    }
    return _wallets[customerId]!;
  }

  // Fetch Transactions List
  List<WalletTransaction> getTransactions(String customerId) {
    return _transactions[customerId] ?? [];
  }

  // Add a transaction
  void addTransaction(String customerId, WalletTransaction tx) {
    final wallet = getOrCreateWallet(customerId);
    
    double nextBalance = wallet.balance;
    double nextLifetime = wallet.lifetimeEarned;
    double nextRedeemed = wallet.totalRedeemed;

    if (tx.type == 'earn' || tx.type == 'bonus') {
      nextBalance += tx.amount;
      nextLifetime += tx.amount;
    } else if (tx.type == 'redeem') {
      nextBalance -= tx.amount;
      nextRedeemed += tx.amount;
    }

    // Determine loyalty tier
    String level = 'Silver';
    if (nextLifetime >= config.platinumThreshold) {
      level = 'Platinum';
    } else if (nextLifetime >= config.goldThreshold) {
      level = 'Gold';
    }

    _wallets[customerId] = wallet.copyWith(
      balance: nextBalance,
      lifetimeEarned: nextLifetime,
      totalRedeemed: nextRedeemed,
      membershipLevel: level,
    );

    if (!_transactions.containsKey(customerId)) {
      _transactions[customerId] = [];
    }
    _transactions[customerId]!.insert(0, tx);
    notifyListeners();
  }

  // Process Daily check-in
  bool claimDailyCheckin(String customerId) {
    final txs = getTransactions(customerId);
    final today = DateTime.now();
    final alreadyClaimed = txs.any((tx) =>
        tx.type == 'bonus' &&
        tx.description == 'Daily Check-In Reward' &&
        tx.createdAt.year == today.year &&
        tx.createdAt.month == today.month &&
        tx.createdAt.day == today.day);

    if (alreadyClaimed) return false;

    addTransaction(
      customerId,
      WalletTransaction(
        id: 'tx_checkin_${DateTime.now().millisecondsSinceEpoch}',
        amount: 10.0,
        type: 'bonus',
        description: 'Daily Check-In Reward',
        createdAt: today,
      ),
    );
    return true;
  }

  // Claim Store rewards
  bool claimRewardOffer(String customerId, String offerId) {
    final offerIdx = rewardOffers.indexWhere((o) => o.id == offerId);
    if (offerIdx < 0) return false;
    final offer = rewardOffers[offerIdx];
    final wallet = getOrCreateWallet(customerId);

    if (wallet.balance < offer.costInCoins) return false;

    addTransaction(
      customerId,
      WalletTransaction(
        id: 'tx_redeem_${DateTime.now().millisecondsSinceEpoch}',
        amount: offer.costInCoins,
        type: 'redeem',
        description: 'Redeemed for "${offer.title}"',
        createdAt: DateTime.now(),
      ),
    );
    return true;
  }

  // Helper for inline math bounds
  int min(int a, int b) => a < b ? a : b;
}
