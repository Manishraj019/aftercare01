import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
import 'package:restaurantos/features/loyalty/presentation/viewmodels/loyalty_viewmodel.dart';
import 'package:restaurantos/features/loyalty/domain/entities/reward_offer_entity.dart';

class RewardStoreScreen extends ConsumerStatefulWidget {
  const RewardStoreScreen({super.key});

  @override
  ConsumerState<RewardStoreScreen> createState() => _RewardStoreScreenState();
}

class _RewardStoreScreenState extends ConsumerState<RewardStoreScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletViewModelProvider);
    final walletNotifier = ref.read(walletViewModelProvider.notifier);
    final offers = ref.watch(rewardStoreProvider).where((o) => o.isActive).toList();

    // Filter by category
    final filteredOffers = _selectedCategory == 'all'
        ? offers
        : offers.where((o) => o.category == _selectedCategory).toList();

    final balance = wallet?.balance ?? 0.0;

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      appBar: AppBar(
        title: Text(
          'Reward Store',
          style: GoogleFonts.playfairDisplaySc(
            color: AppTheme.primaryGold,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.bgDeepBurgundy,
        elevation: 0,
        leading: IconButton(
          key: const Key('storeBackButton'),
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGold),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Balance Header Panel
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: AppTheme.bgDarkPanel,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR BALANCE',
                      style: GoogleFonts.spaceMono(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          balance.toInt().toString(),
                          style: GoogleFonts.playfairDisplaySc(
                            color: AppTheme.primaryGold,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SuperCoins',
                          style: GoogleFonts.karla(
                            color: AppTheme.pureWhite,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(Icons.stars, color: AppTheme.primaryGold, size: 36),
              ],
            ),
          ),

          // 2. Category Filter Pills
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryPill('All Offers', 'all'),
                _buildCategoryPill('Beverages', 'beverage'),
                _buildCategoryPill('Desserts', 'dessert'),
                _buildCategoryPill('Discounts', 'discount'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Grid of offers
          Expanded(
            child: filteredOffers.isEmpty
                ? _buildEmptyStore()
                : GridView.builder(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 40),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filteredOffers.length,
                    itemBuilder: (context, index) {
                      return _buildOfferCard(filteredOffers[index], balance, walletNotifier);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String title, String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          title,
          style: GoogleFonts.karla(
            color: isSelected ? Colors.black : AppTheme.pureWhite,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.primaryGold,
        backgroundColor: AppTheme.bgDarkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppTheme.primaryGold : AppTheme.borderLight),
        ),
        showCheckmark: false,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = category;
            });
          }
        },
      ),
    );
  }

  Widget _buildOfferCard(RewardOfferEntity offer, double balance, WalletNotifier walletNotifier) {
    final canAfford = balance >= offer.costInCoins;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgDarkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    offer.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.bgDarkCharcoal,
                      child: const Icon(Icons.broken_image, color: Colors.white24),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGold, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.stars, color: AppTheme.primaryGold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.costInCoins.toInt()} Coins',
                            style: GoogleFonts.spaceMono(
                              color: AppTheme.primaryGold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Text Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    offer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplaySc(
                      color: AppTheme.pureWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    offer.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.karla(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: Key('claim_${offer.id}'),
                    onPressed: canAfford
                        ? () => _claimOffer(context, offer, walletNotifier)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? AppTheme.primaryGold : Colors.white10,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      canAfford ? 'CLAIM OFFER' : 'INSUFFICIENT COINS',
                      style: GoogleFonts.karla(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: canAfford ? Colors.black : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _claimOffer(BuildContext context, RewardOfferEntity offer, WalletNotifier walletNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgDarkPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Claim Reward Offer?',
          style: GoogleFonts.playfairDisplaySc(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Confirm exchanging ${offer.costInCoins.toInt()} SuperCoins for "${offer.title}".',
          style: GoogleFonts.karla(color: AppTheme.textLight),
        ),
        actions: [
          TextButton(
            child: Text('CANCEL', style: GoogleFonts.karla(color: AppTheme.textMuted)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            key: const Key('confirmClaimButton'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black),
            child: Text('CONFIRM', style: GoogleFonts.karla(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(context);
              final success = walletNotifier.redeemOffer(offer.id);
              if (success) {
                _showPromoCodeDialog(context, offer);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to claim reward. Please try again.', style: GoogleFonts.karla(color: AppTheme.pureWhite)),
                    backgroundColor: AppTheme.nonVegRed,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPromoCodeDialog(BuildContext context, RewardOfferEntity offer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgDarkPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reward Unlocked!',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppTheme.vegGreen, size: 56),
            const SizedBox(height: 16),
            Text(
              'Copy the promo code below and apply it during checkout to claim your reward:',
              textAlign: TextAlign.center,
              style: GoogleFonts.karla(color: AppTheme.textLight, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.bgDarkCharcoal,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryGold.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    offer.promoCode,
                    style: GoogleFonts.spaceMono(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryGold),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: offer.promoCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Code copied to clipboard!', style: GoogleFonts.karla(color: AppTheme.pureWhite)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('DONE', style: GoogleFonts.karla(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStore() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.storefront_outlined, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            'No Active Rewards',
            style: GoogleFonts.playfairDisplaySc(
              color: AppTheme.pureWhite,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back later for exciting offers!',
            style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
