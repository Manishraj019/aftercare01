import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  Widget _buildStatusIndicator(BuildContext context, String status) {
    final statusList = ['placed', 'preparing', 'out_for_delivery', 'delivered'];
    final statusNames = ['Placed', 'Preparing', 'On the way', 'Delivered'];
    final statusIcons = [
      Icons.receipt_long_rounded,
      Icons.outdoor_grill_rounded,
      Icons.delivery_dining_rounded,
      Icons.check_circle_rounded,
    ];

    final currentIdx = statusList.indexOf(status);

    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.nonVegRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel_rounded, color: AppTheme.nonVegRed, size: 20),
            const SizedBox(width: 8),
            Text('Order Cancelled',
                style: GoogleFonts.inter(
                  color: AppTheme.nonVegRed, fontWeight: FontWeight.bold, fontSize: 13,
                )),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(statusList.length, (index) {
        final isActive = index <= currentIdx;
        final isCompleted = index < currentIdx;
        final color = isActive ? AppTheme.primaryBurgundy : AppTheme.borderLight;

        return Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primaryBurgundy.withValues(alpha: 0.1) : AppTheme.bgDarkPanel,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? AppTheme.primaryBurgundy : AppTheme.borderLight,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(statusIcons[index], color: isActive ? AppTheme.primaryBurgundy : AppTheme.textMuted, size: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusNames[index],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? AppTheme.pureWhite : AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < statusList.length - 1)
                Container(
                  width: 24, height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppTheme.primaryBurgundy : AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(orderHistoryViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/customer'),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryBurgundy,
        backgroundColor: AppTheme.pureWhite,
        onRefresh: () => ref.read(orderHistoryViewModelProvider.notifier).fetchOrders(),
        child: ordersState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBurgundy),
          ),
          error: (err, _) => Center(
            child: Text('Error: $err', style: GoogleFonts.inter(color: AppTheme.textMuted)),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDarkPanel,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          size: 64, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 24),
                    Text('No orders yet',
                        style: GoogleFonts.poppins(
                          color: AppTheme.pureWhite, fontSize: 22, fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    Text('Your delicious journey begins here.',
                        style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 15)),
                  ],
                ),
              );
            }

            final activeOrders = orders.where((o) => o.status != 'delivered' && o.status != 'cancelled').toList();
            final pastOrders = orders.where((o) => o.status == 'delivered' || o.status == 'cancelled').toList();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (activeOrders.isNotEmpty) ...[
                  Text('Active Orders',
                      style: GoogleFonts.poppins(
                        color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 12),
                  ...activeOrders.map((order) {
                    final itemsSummary = order.items.map((i) => '${i.quantity} x ${i.name}').join(', ');
                    return Container(
                      key: Key('active_${order.id}'),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10, offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgDarkPanel,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('ID: #${order.id}',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.pureWhite, fontSize: 12, fontWeight: FontWeight.w600,
                                    )),
                              ),
                              Text('\$${order.total.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.pureWhite)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(itemsSummary,
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted, fontSize: 14, height: 1.5,
                              ),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(color: AppTheme.borderLight),
                          ),
                          _buildStatusIndicator(context, order.status),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                if (pastOrders.isNotEmpty) ...[
                  Text('Past Orders',
                      style: GoogleFonts.poppins(
                        color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 12),
                  ...pastOrders.map((order) {
                    final itemsSummary = order.items.map((i) => '${i.quantity} x ${i.name}').join(', ');
                    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt);
                    final isDelivered = order.status == 'delivered';

                    return Container(
                      key: Key('past_${order.id}'),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ID: #${order.id}',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.pureWhite, fontSize: 14, fontWeight: FontWeight.w600,
                                  )),
                              Text('\$${order.total.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.pureWhite, fontSize: 15, fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(itemsSummary,
                              style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 13),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formattedDate,
                                  style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDelivered ? AppTheme.vegGreen.withValues(alpha: 0.1) : AppTheme.nonVegRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(isDelivered ? 'Delivered' : 'Cancelled',
                                    style: GoogleFonts.inter(
                                      color: isDelivered ? AppTheme.vegGreen : AppTheme.nonVegRed,
                                      fontSize: 12, fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
