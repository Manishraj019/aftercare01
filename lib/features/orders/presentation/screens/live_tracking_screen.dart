import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/checkout_viewmodel.dart';
import 'package:restaurantos/features/orders/data/repositories/api_order_repository.dart';

final modifyingOrderIdProvider = StateProvider<String?>((ref) => null);

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const LiveTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int _getSecondsRemaining(OrderEntity order) {
    if (order.status == 'Received' || order.status == 'Preparing') {
      final elapsedSeconds = DateTime.now().difference(order.createdAt).inSeconds;
      final totalSeconds = (order.preparationTimeMinutes * 60).toInt();
      final remaining = totalSeconds - elapsedSeconds;
      return remaining.clamp(0, totalSeconds);
    }
    return 0; // Ready to Serve / Served
  }

  void _modifyOrder(OrderEntity order) {
    // Populate the cart with existing items to allow modifications
    ref.read(cartViewModelProvider.notifier).setCartItems(order.items);
    
    // Set modifying order ID in checkout notifier
    ref.read(modifyingOrderIdProvider.notifier).state = order.id;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cart populated with ${order.kotNumber ?? "Order"}. You can now modify items.', style: GoogleFonts.karla(color: AppTheme.pureWhite)),
        backgroundColor: AppTheme.primaryGold,
      ),
    );

    // Redirect to menu to add/edit items
    context.go('/customer/menu');
  }

  // AI Merge Recommendation Engine
  Widget? _buildAiMergeRecommendation(List<OrderEntity> sessionKots) {
    // Find if there is a preparing KOT and a newly received KOT
    OrderEntity? preparingKot;
    OrderEntity? receivedKot;

    for (final kot in sessionKots) {
      if (kot.status == 'Preparing' && preparingKot == null) {
        preparingKot = kot;
      }
      if (kot.status == 'Received' && receivedKot == null) {
        receivedKot = kot;
      }
    }

    if (preparingKot != null && receivedKot != null) {
      final preparingRemainingSecs = _getSecondsRemaining(preparingKot);
      final preparingRemainingMins = preparingRemainingSecs / 60.0;
      
      // Get longest item prep time for received KOT
      double receivedPrepTime = 0.0;
      for (final item in receivedKot.items) {
        final pt = ApiOrderRepository.getItemPrepTime(item.name);
        if (pt > receivedPrepTime) receivedPrepTime = pt;
      }

      if (receivedPrepTime <= preparingRemainingMins + 1.0) {
        return _buildAiCard(
          "Prepare ${receivedKot.kotNumber ?? 'new order'} items now so both orders can be served hot together!",
          icon: Icons.flash_on,
        );
      } else {
        return _buildAiCard(
          "Serve ${preparingKot.kotNumber ?? 'first order'} items first. ${receivedKot.kotNumber ?? 'New order'} has items that require longer cooking time.",
          icon: Icons.hourglass_empty,
        );
      }
    }
    return null;
  }

  Widget _buildAiCard(String recommendation, {required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGold.withOpacity(0.15),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryGold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI MERGE RECOMMENDATION',
                  style: GoogleFonts.spaceMono(
                    color: AppTheme.primaryGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recommendation,
                  style: GoogleFonts.karla(color: AppTheme.pureWhite, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(orderHistoryViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      appBar: AppBar(
        title: Text('Session Tracking', style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: AppTheme.bgDeepBurgundy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGold),
          onPressed: () => context.go('/customer/orders'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryGold),
            onPressed: () {
              ref.read(modifyingOrderIdProvider.notifier).state = null;
              context.go('/customer/menu');
            },
            tooltip: 'Add More Food',
          ),
        ],
      ),
      body: ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        error: (err, _) => Center(child: Text('Error: $err', style: GoogleFonts.karla(color: Colors.white))),
        data: (orders) {
          final targetOrderIdx = orders.indexWhere((o) => o.id == widget.orderId);
          if (targetOrderIdx < 0) {
            return Center(
              child: Text(
                'Order not found',
                style: GoogleFonts.karla(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final targetOrder = orders[targetOrderIdx];
          final sessionId = targetOrder.diningSessionId;

          // Fetch all KOTs for the active dining session
          final sessionKots = sessionId != null
              ? orders.where((o) => o.diningSessionId == sessionId).toList()
              : [targetOrder];
          
          // Sort by creation time (KOT-001 first)
          sessionKots.sort((a, b) => a.createdAt.compareTo(b.createdAt));

          final hasUnservedKots = sessionKots.any((o) => o.status != 'Served');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Session Banner ──
                GlassContainer(
                  blur: 15,
                  opacity: 0.5,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        sessionId != null ? 'DINING SESSION: $sessionId' : 'INDIVIDUAL ORDER',
                        style: GoogleFonts.spaceMono(color: AppTheme.primaryGold, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        targetOrder.tableNumber != null ? 'Table ${targetOrder.tableNumber}' : 'Takeaway / Delivery',
                        style: GoogleFonts.karla(color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      if (!hasUnservedKots) ...[
                        const SizedBox(height: 12),
                        const Icon(Icons.check_circle, color: AppTheme.vegGreen, size: 48),
                        const SizedBox(height: 6),
                        Text(
                          'All items served! Proceed to checkout.',
                          style: GoogleFonts.karla(color: AppTheme.vegGreen, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // AI suggestions
                if (sessionKots.length > 1 && _buildAiMergeRecommendation(sessionKots) != null) ...[
                  _buildAiMergeRecommendation(sessionKots)!,
                ],

                // ── KOT List ──
                Text(
                  'Kitchen Order Tickets (KOTs)',
                  style: GoogleFonts.playfairDisplaySc(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 12),

                ...sessionKots.map((kot) => _buildKotCard(context, kot)),
                
                const SizedBox(height: 24),
                // Add more food shortcut
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(modifyingOrderIdProvider.notifier).state = null;
                    context.go('/customer/menu');
                  },
                  icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                  label: const Text('ADD MORE FOOD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKotCard(BuildContext context, OrderEntity kot) {
    final secsRemaining = _getSecondsRemaining(kot);
    final isDone = kot.status == 'Ready to Serve' || kot.status == 'Served';
    final canModify = kot.status == 'Received' || kot.status == 'Preparing';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: AppTheme.primaryGold,
        collapsedIconColor: AppTheme.textMuted,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              kot.kotNumber ?? 'KOT-${kot.id.substring(kot.id.length - 3).toUpperCase()}',
              style: GoogleFonts.spaceMono(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(kot.status),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                kot.status.toUpperCase(),
                style: GoogleFonts.karla(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            isDone 
                ? 'Cooked & Plated' 
                : (kot.status == 'Preparing' 
                    ? 'Cooking: ${_formatDuration(secsRemaining)} left' 
                    : 'Awaiting Acceptance'),
            style: GoogleFonts.karla(
              color: kot.status == 'Preparing' ? AppTheme.primaryGold : AppTheme.textMuted, 
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stepper Stage
                _buildStepper(kot.status),
                const Divider(color: AppTheme.borderLight, height: 24),

                // Items list with item status
                Text('Items', style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                ...kot.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x ${item.name}',
                                  style: GoogleFonts.karla(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (item.notes != null || item.spiceLevel != null)
                                  Text(
                                    '${item.spiceLevel != null ? "Spice: " + item.spiceLevel! : ""}${item.notes != null ? " (" + item.notes! + ")" : ""}',
                                    style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getItemStatusColor(item.status).withOpacity(0.12),
                              border: Border.all(color: _getItemStatusColor(item.status).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.status,
                              style: GoogleFonts.karla(
                                color: _getItemStatusColor(item.status),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                if (canModify) ...[
                  const Divider(color: AppTheme.borderLight, height: 24),
                  OutlinedButton.icon(
                    onPressed: () => _modifyOrder(kot),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('MODIFY KOT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGold,
                      side: const BorderSide(color: AppTheme.primaryGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(String status) {
    final stages = ['Received', 'Preparing', 'Ready to Serve', 'Served'];
    final currentIdx = stages.indexOf(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(stages.length, (index) {
        final isActive = index <= currentIdx;
        final isDone = index < currentIdx;

        return Expanded(
          child: Row(
            children: [
              // Circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone 
                      ? AppTheme.vegGreen 
                      : (isActive ? AppTheme.primaryGold.withOpacity(0.2) : Colors.transparent),
                  border: Border.all(
                    color: isDone ? AppTheme.vegGreen : (isActive ? AppTheme.primaryGold : AppTheme.borderLight),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isDone ? Icons.check : Icons.circle,
                  color: isDone ? Colors.black : (isActive ? AppTheme.primaryGold : AppTheme.borderLight),
                  size: isDone ? 12 : 6,
                ),
              ),
              // Line
              if (index < stages.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < currentIdx ? AppTheme.vegGreen : AppTheme.borderLight,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Received':
        return Colors.orange;
      case 'Preparing':
        return AppTheme.primaryGold;
      case 'Ready to Serve':
        return AppTheme.vegGreen;
      case 'Served':
        return Colors.blue;
      default:
        return AppTheme.textMuted;
    }
  }

  Color _getItemStatusColor(String status) {
    switch (status) {
      case 'Waiting':
        return Colors.orange;
      case 'Preparing':
        return AppTheme.primaryGold;
      case 'Ready':
        return AppTheme.vegGreen;
      case 'Served':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
