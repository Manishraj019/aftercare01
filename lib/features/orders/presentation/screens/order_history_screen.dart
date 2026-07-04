import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  Widget _buildStatusIndicator(BuildContext context, String status) {
    final statusList = ['placed', 'preparing', 'out_for_delivery', 'delivered'];
    final statusNames = ['Placed', 'Preparing', 'Out', 'Delivered'];
    final statusIcons = [Icons.receipt_long, Icons.outdoor_grill, Icons.delivery_dining, Icons.home];

    final currentIdx = statusList.indexOf(status);

    if (status == 'cancelled') {
      return const Row(
        children: [
          Icon(Icons.cancel, color: Colors.redAccent, size: 20),
          SizedBox(width: 8),
          Text('Cancelled', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(statusList.length, (index) {
        final isActive = index <= currentIdx;
        final color = isActive
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade300;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                Icon(statusIcons[index], color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  statusNames[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? color : Colors.grey,
                  ),
                ),
              ],
            ),
            if (index < statusList.length - 1)
              Container(
                width: 30,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: (index < currentIdx)
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(orderHistoryViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/customer'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(orderHistoryViewModelProvider.notifier).fetchOrders(),
        child: ordersState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (orders) {
            if (orders.isEmpty) {
              return const Center(
                child: Text('No orders found. Add items to cart and place an order!'),
              );
            }

            final activeOrders = orders.where((o) => o.status != 'delivered' && o.status != 'cancelled').toList();
            final pastOrders = orders.where((o) => o.status == 'delivered' || o.status == 'cancelled').toList();

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (activeOrders.isNotEmpty) ...[
                  const Text(
                    'Active Orders',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ...activeOrders.map((order) {
                    final itemsSummary = order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
                    return Card(
                      key: Key('active_${order.id}'),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ID: #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '\$${order.total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              itemsSummary,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Divider(height: 24),
                            _buildStatusIndicator(context, order.status),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                if (pastOrders.isNotEmpty) ...[
                  const Text(
                    'Order History',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  ...pastOrders.map((order) {
                    final itemsSummary = order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
                    final formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt);

                    return Card(
                      key: Key('past_${order.id}'),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ID: #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('\$${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(itemsSummary, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: order.status == 'delivered'
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    order.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: order.status == 'delivered' ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
