import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';
import 'package:restaurantos/features/staff/presentation/viewmodels/inventory_viewmodel.dart';

// ─── Explicit KDS Dark Palette ───────────────
const Color _bg     = Color(0xFF0D0F1A);
const Color _panel  = Color(0xFF161929);
const Color _card   = Color(0xFF1E2235);
const Color _border = Color(0xFF2D3148);
const Color _white  = Color(0xFFECEDF5);
const Color _muted  = Color(0xFF7B7F99);
const Color _blue   = Color(0xFF4F8EF7);
const Color _amber  = Color(0xFFF59E0B);
const Color _green  = Color(0xFF22C55E);
const Color _red    = Color(0xFFEF4444);
const Color _gold   = Color(0xFFE9A23B);

class ChefDashboardScreen extends ConsumerStatefulWidget {
  const ChefDashboardScreen({super.key});
  @override
  ConsumerState<ChefDashboardScreen> createState() => _ChefDashboardScreenState();
}

class _ChefDashboardScreenState extends ConsumerState<ChefDashboardScreen> {
  Timer? _ticker;
  // Per-order custom time map: orderId -> minutes
  final Map<String, double> _customTimes = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(orderHistoryViewModelProvider.notifier).fetchOrders());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }

  // ── Custom timing dialog ──────────────────
  Future<void> _showTimingDialog(OrderEntity order) async {
    double chosen = _customTimes[order.id] ?? order.preparationTimeMinutes;
    final ctrl = TextEditingController(text: chosen.toInt().toString());

    await showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: ThemeData.dark().copyWith(
          dialogBackgroundColor: _panel,
        ),
        child: AlertDialog(
          backgroundColor: _panel,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.timer_rounded, color: _amber, size: 22),
              const SizedBox(width: 10),
              Text('Set Cooking Time',
                  style: GoogleFonts.poppins(color: _white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order: ${order.items.map((i) => i.name).join(', ')}',
                  style: GoogleFonts.karla(color: _muted, fontSize: 13)),
              const SizedBox(height: 20),
              // Quick time presets
              Text('Quick Select', style: GoogleFonts.karla(color: _muted, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 15, 20, 30, 45].map((min) {
                  final isSelected = ctrl.text == '$min';
                  return GestureDetector(
                    onTap: () => setState(() => ctrl.text = '$min'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _amber.withOpacity(0.2) : _border,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? _amber : Colors.transparent),
                      ),
                      child: Text('$min min',
                          style: GoogleFonts.karla(
                              color: isSelected ? _amber : _white,
                              fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Custom input
              Text('Or enter custom time', style: GoogleFonts.karla(color: _muted, fontSize: 12, letterSpacing: 1)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(color: _white, fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _border,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        suffixText: 'min',
                        suffixStyle: GoogleFonts.karla(color: _muted),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.karla(color: _muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final mins = double.tryParse(ctrl.text) ?? order.preparationTimeMinutes;
                setState(() => _customTimes[order.id] = mins);
                Navigator.pop(ctx);
              },
              child: Text('Set Time', style: GoogleFonts.karla(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status update ─────────────────────────
  Future<void> _updateStatus(OrderEntity order, String newStatus) async {
    final notifier = ref.read(orderHistoryViewModelProvider.notifier);
    OrderEntity updated = order.copyWith(status: newStatus);
    if (newStatus == 'Preparing') {
      // Check inventory
      final inv = ref.read(inventoryViewModelProvider.notifier);
      final req = {'Cheese': 0.2, 'Pizza Dough': 1.0};
      if (!inv.checkAvailability(req)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: _red,
          content: Text('⚠️  Inventory shortage! Cannot start cooking.',
              style: GoogleFonts.karla(color: Colors.white)),
        ));
        return;
      }
      inv.deductIngredients(req);
      // Apply custom time if set
      final customMin = _customTimes[order.id];
      updated = updated.copyWith(
        actualStartTime: DateTime.now(),
        preparationTimeMinutes: customMin ?? order.preparationTimeMinutes,
      );
    }
    await notifier.addOrder(updated);
  }

  void _addDelay(OrderEntity order, double mins) {
    ref.read(orderHistoryViewModelProvider.notifier)
        .addOrder(order.copyWith(chefDelayMinutes: order.chefDelayMinutes + mins));
  }

  // ── Timer remaining ───────────────────────
  Duration? _remaining(OrderEntity o) {
    if (o.actualStartTime == null) return null;
    final total = ((_customTimes[o.id] ?? o.preparationTimeMinutes) + o.chefDelayMinutes) * 60;
    return Duration(seconds: total.toInt()) - DateTime.now().difference(o.actualStartTime!);
  }

  // ── Build ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(orderHistoryViewModelProvider);
    final all    = state.valueOrNull?.isNotEmpty == true
        ? state.valueOrNull!
        : _demoOrders();

    final newOrds  = all.where((o) => o.status == 'Received' || o.status == 'New').toList();
    final prepOrds = all.where((o) => o.status == 'Preparing').toList();
    final readyOrds= all.where((o) => o.status == 'Ready to Serve' || o.status == 'Ready').toList();

    return Material(
      color: _bg,
      child: Column(
        children: [
          _topBar(newOrds.length, prepOrds.length, readyOrds.length),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _column('🆕  NEW ORDERS', newOrds,   _blue),
                Container(width: 1, color: _border),
                _column('🔥  PREPARING',  prepOrds,  _amber),
                Container(width: 1, color: _border),
                _column('✅  READY',      readyOrds, _green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────
  Widget _topBar(int n, int p, int r) {
    return Container(
      color: _panel,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.soup_kitchen_rounded, color: _gold, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kitchen Display System',
                  style: GoogleFonts.poppins(color: _white, fontWeight: FontWeight.bold, fontSize: 17)),
              Row(children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: _green)),
                const SizedBox(width: 5),
                Text('LIVE', style: GoogleFonts.karla(color: _green, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
          const Spacer(),
          _chip('New',       n, _blue),
          const SizedBox(width: 8),
          _chip('Preparing', p, _amber),
          const SizedBox(width: 8),
          _chip('Ready',     r, _green),
          const SizedBox(width: 20),
          TextButton.icon(
            onPressed: () {
              ref.read(authViewModelProvider.notifier).logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout, color: _muted, size: 16),
            label: Text('Sign Out', style: GoogleFonts.karla(color: _muted, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Text('$label  $count',
          style: GoogleFonts.karla(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // ── Column ────────────────────────────────
  Widget _column(String title, List<OrderEntity> orders, Color accent) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _panel,
              border: Border(
                bottom: BorderSide(color: accent, width: 2.5),
              ),
            ),
            child: Text(title,
                style: GoogleFonts.karla(
                    color: _white, fontWeight: FontWeight.bold,
                    fontSize: 13, letterSpacing: 1.2)),
          ),
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text('No orders',
                        style: GoogleFonts.karla(color: _muted, fontSize: 14)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: orders.length,
                    itemBuilder: (_, i) => _orderCard(orders[i], accent),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Order Card ────────────────────────────
  Widget _orderCard(OrderEntity order, Color accent) {
    final rem       = _remaining(order);
    final isDelayed = rem != null && rem.isNegative;
    final customMin = _customTimes[order.id];

    // Timer label
    String timerTxt;
    if (rem == null) {
      timerTxt = customMin != null
          ? 'Set: ${customMin.toInt()} min'
          : '~${order.preparationTimeMinutes.toInt()} min';
    } else if (isDelayed) {
      final a = rem.abs();
      timerTxt = '⚠ DELAYED  ${a.inMinutes}m ${a.inSeconds % 60}s';
    } else {
      timerTxt = '${rem.inMinutes}m ${rem.inSeconds % 60}s';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDelayed ? _red : _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header strip ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(Icons.table_restaurant, color: accent, size: 15),
                const SizedBox(width: 6),
                Text('Table ${order.tableNumber ?? 'Takeaway'}',
                    style: GoogleFonts.poppins(
                        color: _white, fontWeight: FontWeight.w600, fontSize: 13)),
                if (order.customerName != null) ...[
                  const SizedBox(width: 8),
                  Text('· ${order.customerName}',
                      style: GoogleFonts.karla(color: _muted, fontSize: 12)),
                ],
                if (order.priority == 'high') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('HIGH',
                        style: GoogleFonts.karla(
                            color: _red, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
                const Spacer(),
                Text('#${order.id.substring(0, 5).toUpperCase()}',
                    style: GoogleFonts.spaceMono(color: _muted, fontSize: 11)),
              ],
            ),
          ),

          // ── Items ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _gold.withOpacity(0.3)),
                      ),
                      child: Text('${item.quantity}x',
                          style: GoogleFonts.poppins(
                              color: _gold, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name.isNotEmpty ? item.name : '(unnamed item)',
                            style: GoogleFonts.karla(
                                color: _white,    // ← Always white text on dark card
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(item.notes!,
                                style: GoogleFonts.karla(color: _muted, fontSize: 11)),
                          if (item.spiceLevel != null && item.spiceLevel!.isNotEmpty)
                            Text('🌶 ${item.spiceLevel}',
                                style: GoogleFonts.karla(color: _amber, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),

          // ── Special instructions ──
          if (order.specialInstructions != null &&
              order.specialInstructions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _amber.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _amber.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, color: _amber, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(order.specialInstructions!,
                          style: GoogleFonts.karla(color: _amber, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Timer & controls row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 15,
                    color: isDelayed ? _red : _muted),
                const SizedBox(width: 5),
                Text(timerTxt,
                    style: GoogleFonts.poppins(
                        color: isDelayed ? _red : _white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                const Spacer(),
                // ── Set custom time button ──
                if (order.status == 'Received' || order.status == 'New')
                  GestureDetector(
                    onTap: () => _showTimingDialog(order),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _amber.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded, size: 13, color: _amber),
                          const SizedBox(width: 4),
                          Text('Set Time',
                              style: GoogleFonts.karla(
                                  color: _amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                // ── Add delay button ──
                if (order.status == 'Preparing') ...[
                  PopupMenuButton<double>(
                    icon: const Icon(Icons.more_time, color: _muted, size: 18),
                    color: _panel,
                    tooltip: 'Add delay',
                    onSelected: (v) => _addDelay(order, v),
                    itemBuilder: (_) => [
                      _pop('+2 min', 'High kitchen load', 2),
                      _pop('+5 min', 'Waiting for stock', 5),
                      _pop('+10 min', 'Equipment issue', 10),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Action button ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: _actionBtn(order, accent),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<double> _pop(String t, String s, double v) => PopupMenuItem(
    value: v,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: GoogleFonts.karla(color: _white, fontWeight: FontWeight.bold)),
        Text(s, style: GoogleFonts.karla(color: _muted, fontSize: 11)),
      ],
    ),
  );

  Widget _actionBtn(OrderEntity order, Color accent) {
    if (order.status == 'Received' || order.status == 'New') {
      return ElevatedButton.icon(
        onPressed: () => _updateStatus(order, 'Preparing'),
        icon: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
        label: Text('Start Cooking',
            style: GoogleFonts.karla(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          elevation: 0,
        ),
      );
    } else if (order.status == 'Preparing') {
      return ElevatedButton.icon(
        onPressed: () => _updateStatus(order, 'Ready to Serve'),
        icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
        label: Text('Mark Ready',
            style: GoogleFonts.karla(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          elevation: 0,
        ),
      );
    } else if (order.status == 'Ready to Serve' || order.status == 'Ready') {
      return OutlinedButton.icon(
        onPressed: () => _updateStatus(order, 'Served'),
        icon: const Icon(Icons.done_all, size: 18, color: _muted),
        label: Text('Mark Served',
            style: GoogleFonts.karla(fontWeight: FontWeight.bold, color: _muted, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _border),
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Demo orders for when no real orders exist ──
  List<OrderEntity> _demoOrders() {
    final now = DateTime.now();
    return [
      OrderEntity(
        id: 'ord_d001', customerId: 'demo', restaurantId: 'r1',
        items: const [
          CartItemEntity(itemId: 'i1', name: 'Wood-Fired Pepperoni Pizza', price: 16.0, quantity: 2, imageUrl: ''),
          CartItemEntity(itemId: 'i2', name: 'Fresh Mint Lime Mojito',     price: 6.0,  quantity: 2, imageUrl: ''),
        ],
        subtotal: 44, tax: 4, deliveryFee: 0, total: 48,
        status: 'Received', deliveryAddress: 'Dine-In', paymentMethod: 'cash',
        createdAt: now.subtract(const Duration(minutes: 2)), updatedAt: now,
        tableNumber: '5', customerName: 'Aditya',
        specialInstructions: 'Extra cheese • Less ice in mojito',
        preparationTimeMinutes: 15, priority: 'high',
      ),
      OrderEntity(
        id: 'ord_d002', customerId: 'demo', restaurantId: 'r1',
        items: const [
          CartItemEntity(itemId: 'i3', name: 'Truffle Mushroom Fettuccine', price: 18.5, quantity: 1, imageUrl: ''),
          CartItemEntity(itemId: 'i4', name: 'Molten Chocolate Lava Cake',  price: 8.5,  quantity: 1, imageUrl: ''),
        ],
        subtotal: 27, tax: 2.7, deliveryFee: 0, total: 29.7,
        status: 'Preparing', deliveryAddress: 'Dine-In', paymentMethod: 'upi',
        createdAt: now.subtract(const Duration(minutes: 12)), updatedAt: now,
        tableNumber: '2', customerName: 'Priya',
        preparationTimeMinutes: 12, actualStartTime: now.subtract(const Duration(minutes: 6)),
        priority: 'normal',
      ),
      OrderEntity(
        id: 'ord_d003', customerId: 'demo', restaurantId: 'r1',
        items: const [
          CartItemEntity(itemId: 'i5', name: 'Crispy Chicken Burger', price: 12.0, quantity: 3, imageUrl: ''),
          CartItemEntity(itemId: 'i6', name: 'Classic Caesar Salad',  price: 9.0,  quantity: 1, imageUrl: ''),
        ],
        subtotal: 45, tax: 4.5, deliveryFee: 0, total: 49.5,
        status: 'Ready to Serve', deliveryAddress: 'Dine-In', paymentMethod: 'card',
        createdAt: now.subtract(const Duration(minutes: 22)), updatedAt: now,
        tableNumber: '8', customerName: 'Rahul',
        preparationTimeMinutes: 10, priority: 'normal',
      ),
    ];
  }
}
