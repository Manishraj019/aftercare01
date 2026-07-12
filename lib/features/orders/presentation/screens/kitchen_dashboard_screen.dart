import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
import 'package:restaurantos/features/orders/data/repositories/api_order_repository.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/features/owner/presentation/screens/owner_dashboard_screen.dart';

class KitchenDashboardScreen extends ConsumerStatefulWidget {
  const KitchenDashboardScreen({super.key});

  @override
  ConsumerState<KitchenDashboardScreen> createState() =>
      _KitchenDashboardScreenState();
}

class _KitchenDashboardScreenState
    extends ConsumerState<KitchenDashboardScreen> {
  @override
  void initState() {
    super.initState();
    ApiOrderRepository.addListener(_onOrdersChanged);
  }

  @override
  void dispose() {
    ApiOrderRepository.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ownerOrders = ref.watch(ownerOrdersProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      appBar: AppBar(
        title: Text(
          'KITCHEN DISPLAY SYSTEM',
          style: GoogleFonts.spaceMono(
              color: AppTheme.primaryGold,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.bgDeepBurgundy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGold),
          onPressed: () => context.go('/landing'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGold),
            onPressed: () =>
                ref.read(ownerOrdersProvider.notifier).fetchOrders(),
          ),
        ],
      ),
      body: ownerOrders.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        error: (err, _) => Center(
            child: Text('Error: $err',
                style: GoogleFonts.karla(color: Colors.white))),
        data: (orders) {
          // Show only orders that are not yet fully served
          final activeOrders =
              orders.where((o) => o.status != 'Served').toList();

          if (activeOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu,
                      size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No active orders in the queue',
                    style: GoogleFonts.karla(
                        color: AppTheme.textMuted, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1200
                  ? 4
                  : (constraints.maxWidth > 800
                      ? 3
                      : (constraints.maxWidth > 500 ? 2 : 1));

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: activeOrders.length,
                itemBuilder: (context, index) {
                  final order = activeOrders[index];
                  return _KitchenOrderCard(order: order);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _KitchenOrderCard extends ConsumerWidget {
  final OrderEntity order;

  const _KitchenOrderCard({required this.order});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Received':
        return Colors.orange;
      case 'Preparing':
        return AppTheme.primaryGold;
      case 'Ready to Serve':
        return AppTheme.vegGreen;
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

  String _getAiStationRecommendation(String name) {
    final n = name.toLowerCase();
    if (n.contains('pizza')) return ' Wood-Fired Pizza Stn (Chef Rahul)';
    if (n.contains('risotto') ||
        n.contains('fettuccine') ||
        n.contains('pasta')) return ' Pasta Stn (Chef Alessandro)';
    if (n.contains('burger')) return ' Grill Stn (Chef John)';
    if (n.contains('mojito') ||
        n.contains('cocktail') ||
        n.contains('coffee') ||
        n.contains('juice') ||
        n.contains('coke')) return ' Beverage (Stn 3)';
    if (n.contains('cake') ||
        n.contains('lava') ||
        n.contains('brownie') ||
        n.contains('dessert')) return ' Dessert Stn (Chef Preeti)';
    return ' Main Cook Line';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasHighPriority = order.priority == 'high';

    // Split items into existing (previously sent) and new (most recent batch)
    final newItemIds = order.newItemsSinceVersion.toSet();
    final hasNewItems = newItemIds.isNotEmpty;

    final existingItems =
        order.items.where((i) => !newItemIds.contains(i.itemId)).toList();
    final newItems =
        order.items.where((i) => newItemIds.contains(i.itemId)).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgDarkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasHighPriority
              ? Colors.redAccent
              : _getStatusColor(order.status).withOpacity(0.3),
          width: hasHighPriority ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasNewItems
                ? Colors.orangeAccent.withOpacity(0.15)
                : _getStatusColor(order.status).withOpacity(0.05),
            blurRadius: hasNewItems ? 20 : 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Order Card Header ──────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show persistent Order Number if available
                    Text(
                      order.orderNumber ??
                          order.kotNumber ??
                          'KOT-${order.id.substring(order.id.length - 3).toUpperCase()}',
                      style: GoogleFonts.spaceMono(
                          color: AppTheme.pureWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    if (order.diningSessionId != null)
                      Text(
                        'Session: ${order.diningSessionId}',
                        style: GoogleFonts.karla(
                            color: AppTheme.textMuted, fontSize: 10),
                      ),
                    if (order.orderNumber != null)
                      Text(
                        'v${order.newItemsSinceVersion.isEmpty ? '' : '  +${order.newItemsSinceVersion.length} NEW'}',
                        style: GoogleFonts.karla(
                            color: hasNewItems
                                ? Colors.orangeAccent
                                : AppTheme.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (hasNewItems) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${newItems.length} NEW',
                          style: GoogleFonts.spaceMono(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: GoogleFonts.karla(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Table + Priority + Time ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      order.tableNumber != null
                          ? 'TABLE: ${order.tableNumber}'
                          : 'TAKEAWAY',
                      style: GoogleFonts.karla(
                          color: AppTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    if (hasHighPriority) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'HIGH PRIORITY',
                          style: GoogleFonts.spaceMono(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${DateTime.now().difference(order.createdAt).inMinutes} min ago',
                  style: GoogleFonts.karla(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(
              color: AppTheme.borderLight, indent: 16, endIndent: 16),

          // ── Items list ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                // ── Previously ordered items (not new) ──
                if (existingItems.isNotEmpty) ...[
                  if (hasNewItems)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'EXISTING ORDER',
                        style: GoogleFonts.spaceMono(
                            color: AppTheme.textMuted,
                            fontSize: 9,
                            letterSpacing: 1),
                      ),
                    ),
                  ...existingItems
                      .map((item) => _itemRow(context, ref, item, isNew: false)),
                ],

                // ── NEW items (most recent batch) ──
                if (newItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.orangeAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_new,
                              color: Colors.orangeAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'NEWLY ADDED',
                            style: GoogleFonts.spaceMono(
                                color: Colors.orangeAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...newItems.map((item) =>
                      _itemRow(context, ref, item, isNew: true)),
                ],
              ],
            ),
          ),

          // ── Special instructions ───────────────────────────────────
          if (order.specialInstructions != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Text(
                  'Inst: ${order.specialInstructions}',
                  style: GoogleFonts.karla(
                      color: Colors.orange[200],
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],

          // ── Action Buttons ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionButtons(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(BuildContext context, WidgetRef ref, item,
      {required bool isNew}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: isNew
            ? const EdgeInsets.all(6)
            : EdgeInsets.zero,
        decoration: isNew
            ? BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.2),
                    width: 1),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (isNew)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.star,
                              color: Colors.orangeAccent, size: 12),
                        ),
                      Expanded(
                        child: Text(
                          '${item.quantity}x  ${item.name}',
                          style: GoogleFonts.karla(
                              color: isNew
                                  ? Colors.orangeAccent
                                  : AppTheme.pureWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tap to cycle status chip
                InkWell(
                  onTap: () {
                    String nextStatus = 'Waiting';
                    if (item.status == 'Waiting') nextStatus = 'Preparing';
                    else if (item.status == 'Preparing') nextStatus = 'Ready';
                    else if (item.status == 'Ready') nextStatus = 'Served';

                    ref
                        .read(ownerOrdersProvider.notifier)
                        .updateItemStatus(order.id, item.itemId, nextStatus);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getItemStatusColor(item.status)
                          .withOpacity(0.12),
                      border: Border.all(
                          color: _getItemStatusColor(item.status)
                              .withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        color: _getItemStatusColor(item.status),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // AI Station assignment
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Row(
                children: [
                  const Icon(Icons.flash_on,
                      color: AppTheme.primaryGold, size: 10),
                  const SizedBox(width: 2),
                  Text(
                    'AI Route:${_getAiStationRecommendation(item.name)}',
                    style: GoogleFonts.karla(
                        color: AppTheme.primaryGold.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            // Customizations
            if (item.spiceLevel != null ||
                (item.addOns != null && item.addOns!.isNotEmpty) ||
                item.notes != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.spiceLevel != null ||
                        (item.addOns != null && item.addOns!.isNotEmpty))
                      Text(
                        'Custom: ${item.spiceLevel ?? "Medium"}${item.addOns != null && item.addOns!.isNotEmpty ? " + " + item.addOns!.join(", ") : ""}',
                        style: GoogleFonts.karla(
                            color: Colors.amber[300], fontSize: 10),
                      ),
                    if (item.notes != null)
                      Text(
                        'Note: "${item.notes}"',
                        style: GoogleFonts.karla(
                            color: Colors.orange[200],
                            fontSize: 10,
                            fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    if (order.status == 'Received') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => ref
                  .read(ownerOrdersProvider.notifier)
                  .updateStatus(order.id, 'Preparing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('START PREPARING',
                  style: GoogleFonts.karla(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5)),
            ),
          ),
        ],
      );
    } else if (order.status == 'Preparing') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => ref
                  .read(ownerOrdersProvider.notifier)
                  .updateStatus(order.id, 'Ready to Serve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('MARK READY',
                  style: GoogleFonts.karla(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5)),
            ),
          ),
        ],
      );
    } else if (order.status == 'Ready to Serve') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => ref
                  .read(ownerOrdersProvider.notifier)
                  .updateStatus(order.id, 'Served'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vegGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('MARK SERVED',
                  style: GoogleFonts.karla(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5)),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
