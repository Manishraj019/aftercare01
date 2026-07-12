import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
import 'package:restaurantos/features/loyalty/presentation/viewmodels/loyalty_viewmodel.dart';
import 'package:restaurantos/features/loyalty/domain/entities/wallet_entity.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletViewModelProvider);
    final walletNotifier = ref.read(walletViewModelProvider.notifier);
    final config = ref.watch(loyaltyConfigProvider);

    if (wallet == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            'Please login to access your wallet.',
            style: GoogleFonts.karla(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final transactions = walletNotifier.transactions;

    // Calculate Tier Progress
    double progress = 0.0;
    double remainingToNext = 0.0;
    String nextTier = '';
    
    if (wallet.membershipLevel == 'Silver') {
      nextTier = 'Gold';
      remainingToNext = (config.goldThreshold - wallet.lifetimeEarned).clamp(0.0, double.infinity);
      progress = (wallet.lifetimeEarned / config.goldThreshold).clamp(0.0, 1.0);
    } else if (wallet.membershipLevel == 'Gold') {
      nextTier = 'Platinum';
      remainingToNext = (config.platinumThreshold - wallet.lifetimeEarned).clamp(0.0, double.infinity);
      progress = ((wallet.lifetimeEarned - config.goldThreshold) / (config.platinumThreshold - config.goldThreshold)).clamp(0.0, 1.0);
    } else {
      nextTier = 'Platinum (Max Level)';
      remainingToNext = 0.0;
      progress = 1.0;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      appBar: AppBar(
        title: Text(
          'Loyalty Wallet',
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
          key: const Key('walletBackButton'),
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGold),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            key: const Key('rewardStoreButton'),
            icon: const Icon(Icons.storefront_rounded, color: AppTheme.primaryGold),
            onPressed: () => context.push('/customer/rewards'),
            tooltip: 'Reward Store',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Balance Glass Card
              _buildBalanceCard(wallet, config),
              const SizedBox(height: 24),

              // 2. Loyalty Tier Progress Card
              _buildTierProgressCard(wallet, progress, remainingToNext, nextTier),
              const SizedBox(height: 24),

              // 3. Quick Actions (Check-In & Browse Store)
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      key: const Key('dailyCheckinButton'),
                      icon: Icons.calendar_today_rounded,
                      label: 'Daily Check-In',
                      subtitle: '+10 Coins Free',
                      onTap: () {
                        final success = walletNotifier.dailyCheckIn();
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Daily Check-In claimed! +10 SuperCoins added.', style: GoogleFonts.karla(color: AppTheme.pureWhite)),
                              backgroundColor: AppTheme.vegGreen,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('You have already claimed your daily check-in reward today.', style: GoogleFonts.karla(color: AppTheme.pureWhite)),
                              backgroundColor: AppTheme.primaryGold,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionButton(
                      key: const Key('goToRewardStoreButton'),
                      icon: Icons.stars_rounded,
                      label: 'Reward Store',
                      subtitle: 'Browse Coupons',
                      onTap: () => context.push('/customer/rewards'),
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 4. Transaction History Timeline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TRANSACTION HISTORY',
                    style: GoogleFonts.spaceMono(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Icon(Icons.history_rounded, color: AppTheme.primaryGold, size: 18),
                ],
              ),
              const SizedBox(height: 16),
              if (transactions.isEmpty)
                _buildEmptyHistory()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionItem(transactions[index]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(WalletEntity wallet, config) {
    return GlassContainer(
      blur: 15,
      opacity: 0.5,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT BALANCE',
                    style: GoogleFonts.spaceMono(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        wallet.balance.toInt().toString(),
                        style: GoogleFonts.playfairDisplaySc(
                          color: AppTheme.pureWhite,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Coins',
                        style: GoogleFonts.karla(
                          color: AppTheme.primaryGold,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getTierColor(wallet.membershipLevel).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getTierColor(wallet.membershipLevel).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  wallet.membershipLevel.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    color: _getTierColor(wallet.membershipLevel),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBalanceStat(
                'Lifetime Earned',
                wallet.lifetimeEarned.toInt().toString(),
                Icons.add_circle_outline_rounded,
                AppTheme.vegGreen,
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildBalanceStat(
                'Total Redeemed',
                wallet.totalRedeemed.toInt().toString(),
                Icons.remove_circle_outline_rounded,
                AppTheme.nonVegRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$value Coins',
          style: GoogleFonts.karla(
            color: AppTheme.pureWhite,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTierProgressCard(WalletEntity wallet, double progress, double remainingToNext, String nextTier) {
    return GlassContainer(
      blur: 15,
      opacity: 0.5,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Membership Tier Status',
                style: GoogleFonts.playfairDisplaySc(
                  color: AppTheme.pureWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (remainingToNext > 0)
                Text(
                  '${remainingToNext.toInt()} more to $nextTier',
                  style: GoogleFonts.karla(
                    color: AppTheme.primaryGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(_getTierColor(wallet.membershipLevel)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wallet.membershipLevel,
                style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (remainingToNext > 0)
                Text(
                  nextTier,
                  style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    Key? key,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primaryGold.withOpacity(0.08) : AppTheme.bgDarkPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary ? AppTheme.primaryGold.withOpacity(0.4) : AppTheme.borderLight,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isPrimary ? AppTheme.primaryGold : AppTheme.pureWhite,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.karla(
                color: AppTheme.pureWhite,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.karla(
                color: isPrimary ? AppTheme.primaryGold.withOpacity(0.8) : AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return GlassContainer(
      blur: 15,
      opacity: 0.5,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Transactions Yet',
              style: GoogleFonts.playfairDisplaySc(
                color: AppTheme.pureWhite,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Order or complete check-ins to earn SuperCoins!',
              style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx) {
    final isEarn = tx.type == 'earn' || tx.type == 'bonus';
    final DateFormat formatter = DateFormat('MMM dd, yyyy • hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isEarn ? AppTheme.vegGreen : AppTheme.nonVegRed).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarn ? Icons.add_rounded : Icons.remove_rounded,
              color: isEarn ? AppTheme.vegGreen : AppTheme.nonVegRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: GoogleFonts.karla(
                    color: AppTheme.pureWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(tx.createdAt),
                  style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${isEarn ? '+' : '-'}${tx.amount.toInt()}',
            style: GoogleFonts.spaceMono(
              color: isEarn ? AppTheme.vegGreen : AppTheme.nonVegRed,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Gold':
        return AppTheme.primaryGold;
      case 'Platinum':
        return Colors.tealAccent;
      default:
        return Colors.grey.shade400;
    }
  }
}
