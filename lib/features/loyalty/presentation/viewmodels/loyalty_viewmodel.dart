import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/loyalty/data/repositories/loyalty_repository.dart';
import 'package:restaurantos/features/loyalty/domain/entities/wallet_entity.dart';
import 'package:restaurantos/features/loyalty/domain/entities/reward_offer_entity.dart';

// 1. Shared Repository Provider
final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  return LoyaltyRepository();
});

// 2. StateNotifier to manage Wallet details of the logged in user
final walletViewModelProvider =
    StateNotifierProvider<WalletNotifier, WalletEntity?>((ref) {
  final repo = ref.watch(loyaltyRepositoryProvider);
  final authState = ref.watch(authViewModelProvider);
  String? customerId;
  if (authState is Authenticated) {
    customerId = authState.user.uid;
  }
  return WalletNotifier(repo, customerId);
});

class WalletNotifier extends StateNotifier<WalletEntity?> {
  final LoyaltyRepository _repo;
  final String? _customerId;

  WalletNotifier(this._repo, this._customerId) : super(null) {
    _loadWallet();
    LoyaltyRepository.addListener(_loadWallet);
  }

  @override
  void dispose() {
    LoyaltyRepository.removeListener(_loadWallet);
    super.dispose();
  }

  void _loadWallet() {
    if (_customerId != null) {
      state = _repo.getOrCreateWallet(_customerId!);
    } else {
      state = null;
    }
  }

  List<WalletTransaction> get transactions {
    if (_customerId == null) return [];
    return _repo.getTransactions(_customerId!);
  }

  bool dailyCheckIn() {
    if (_customerId == null) return false;
    return _repo.claimDailyCheckin(_customerId!);
  }

  bool redeemOffer(String offerId) {
    if (_customerId == null) return false;
    return _repo.claimRewardOffer(_customerId!, offerId);
  }
}

// 3. StateNotifier to manage Reward Store Offers
final rewardStoreProvider =
    StateNotifierProvider<RewardStoreNotifier, List<RewardOfferEntity>>((ref) {
  return RewardStoreNotifier();
});

class RewardStoreNotifier extends StateNotifier<List<RewardOfferEntity>> {
  RewardStoreNotifier() : super(List.from(LoyaltyRepository.rewardOffers)) {
    LoyaltyRepository.addListener(_loadOffers);
  }

  @override
  void dispose() {
    LoyaltyRepository.removeListener(_loadOffers);
    super.dispose();
  }

  void _loadOffers() {
    state = List.from(LoyaltyRepository.rewardOffers);
  }

  void createOffer(RewardOfferEntity offer) {
    LoyaltyRepository.rewardOffers.add(offer);
    LoyaltyRepository.notifyListeners();
  }

  void toggleOfferStatus(String offerId) {
    final idx = LoyaltyRepository.rewardOffers.indexWhere((o) => o.id == offerId);
    if (idx >= 0) {
      final o = LoyaltyRepository.rewardOffers[idx];
      LoyaltyRepository.rewardOffers[idx] = RewardOfferEntity(
        id: o.id,
        title: o.title,
        description: o.description,
        costInCoins: o.costInCoins,
        category: o.category,
        imageUrl: o.imageUrl,
        isActive: !o.isActive,
        promoCode: o.promoCode,
      );
      LoyaltyRepository.notifyListeners();
    }
  }
}

// 4. Configuration Provider for Admin Control Panel
final loyaltyConfigProvider =
    StateNotifierProvider<LoyaltyConfigNotifier, LoyaltyConfig>((ref) {
  return LoyaltyConfigNotifier();
});

class LoyaltyConfigNotifier extends StateNotifier<LoyaltyConfig> {
  LoyaltyConfigNotifier() : super(LoyaltyRepository.config);

  void updateConfig(LoyaltyConfig newConfig) {
    LoyaltyRepository.config = newConfig;
    state = newConfig;
    LoyaltyRepository.notifyListeners();
  }
}

// 5. Campaigns provider for Owner Campaigns Launch Panel
final loyaltyCampaignsProvider =
    StateNotifierProvider<CampaignsNotifier, List<LoyaltyCampaign>>((ref) {
  return CampaignsNotifier();
});

class CampaignsNotifier extends StateNotifier<List<LoyaltyCampaign>> {
  CampaignsNotifier() : super(List.from(LoyaltyRepository.campaigns)) {
    LoyaltyRepository.addListener(_loadCampaigns);
  }

  @override
  void dispose() {
    LoyaltyRepository.removeListener(_loadCampaigns);
    super.dispose();
  }

  void _loadCampaigns() {
    state = List.from(LoyaltyRepository.campaigns);
  }

  void addCampaign(LoyaltyCampaign campaign) {
    LoyaltyRepository.campaigns.add(campaign);
    LoyaltyRepository.notifyListeners();
  }

  void toggleCampaign(String campaignId) {
    final idx = LoyaltyRepository.campaigns.indexWhere((c) => c.id == campaignId);
    if (idx >= 0) {
      final c = LoyaltyRepository.campaigns[idx];
      LoyaltyRepository.campaigns[idx] = LoyaltyCampaign(
        id: c.id,
        name: c.name,
        description: c.description,
        multiplier: c.multiplier,
        isActive: !c.isActive,
      );
      LoyaltyRepository.notifyListeners();
    }
  }
}
