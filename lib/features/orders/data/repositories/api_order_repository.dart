import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/domain/entities/dining_session.dart';
import 'package:restaurantos/features/orders/domain/entities/order_history_entry.dart';
import 'package:restaurantos/features/orders/domain/repositories/order_repository.dart';

/// In-memory implementation of [OrderRepository].
///
/// KEY INVARIANT:
///   For every active [DiningSession] there is AT MOST ONE [OrderEntity] in [_orders]
///   whose [id] matches [DiningSession.masterOrderId].
///   Every call to [appendItemsToSession] either:
///     (a) creates that master order if it doesn't exist yet, or
///     (b) merges new items into the existing master order.
///   A NEW ORDER IS NEVER CREATED for a table that already has an active session.
class ApiOrderRepository implements OrderRepository {
  static final List<OrderEntity> _orders = [];
  static final List<DiningSession> _sessions = [];
  static final List<OrderHistoryEntry> _orderHistory = [];
  static final List<VoidCallback> _listeners = [];
  static String _kitchenLoadStatus = 'Free';
  static const _uuid = Uuid();

  // ── Listener helpers ─────────────────────────────────────────────
  static void addListener(VoidCallback listener) => _listeners.add(listener);
  static void removeListener(VoidCallback listener) =>
      _listeners.remove(listener);
  static void notifyListeners() {
    for (final l in List.of(_listeners)) {
      try {
        l();
      } catch (_) {}
    }
  }

  // ── Order Number Generator ───────────────────────────────────────
  /// Generates a human-readable order number like '#A1025'.
  /// Uses the alphabet prefix + 4-digit incrementing number.
  static String _generateOrderNumber() {
    const prefixes = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final totalSessions = _sessions.length;
    final prefix = prefixes[totalSessions ~/ 9000 % prefixes.length];
    final num = (1000 + totalSessions % 9000).toString();
    return '#$prefix$num';
  }

  /// Generates a Session ID like 'SID-7HG82K91'.
  static String _generateSessionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final suffix =
        List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'SID-$suffix';
  }

  // ── Smart ETA helpers ─────────────────────────────────────────────
  static double getItemPrepTime(String name) {
    final n = name.toLowerCase();
    if (n.contains('pizza')) return 15.0;
    if (n.contains('burger')) return 8.0;
    if (n.contains('coffee') ||
        n.contains('cocktail') ||
        n.contains('mojito') ||
        n.contains('juice') ||
        n.contains('coke')) return 2.0;
    if (n.contains('pasta') ||
        n.contains('risotto') ||
        n.contains('fettuccine')) return 12.0;
    if (n.contains('fries') || n.contains('chips')) return 5.0;
    return 10.0;
  }

  static double calculateOrderETA(OrderEntity order) {
    if (order.items.isEmpty) return 0.0;

    double longestItemPrep = 0.0;
    for (final item in order.items) {
      final pt = getItemPrepTime(item.name);
      if (pt > longestItemPrep) longestItemPrep = pt;
    }

    double queueDelay = 0.0;
    for (final o in _orders) {
      if (o.id == order.id) break;
      if (o.status == 'Received' || o.status == 'Preparing') {
        double oMax = 0.0;
        for (final item in o.items) {
          final pt = getItemPrepTime(item.name);
          if (pt > oMax) oMax = pt;
        }
        queueDelay += oMax;
      }
    }

    double loadDelay = 0.0;
    switch (_kitchenLoadStatus) {
      case 'Moderate':
        loadDelay = 3.0;
        break;
      case 'Busy':
        loadDelay = 8.0;
        break;
      case 'Peak Hours':
        loadDelay = 15.0;
        break;
      case 'Maintenance':
        loadDelay = 20.0;
        break;
      default:
        loadDelay = 0.0;
    }

    return longestItemPrep + queueDelay + loadDelay + order.ownerDelayMinutes;
  }

  // ── Kitchen load ──────────────────────────────────────────────────
  @override
  String getKitchenLoadStatus() => _kitchenLoadStatus;

  @override
  void setKitchenLoadStatus(String status) {
    _kitchenLoadStatus = status;
    for (int i = 0; i < _orders.length; i++) {
      if (_orders[i].status == 'Received' ||
          _orders[i].status == 'Preparing') {
        _orders[i] = _orders[i].copyWith(
          preparationTimeMinutes: calculateOrderETA(_orders[i]),
        );
      }
    }
    notifyListeners();
  }

  // ── Legacy placeOrder (kept for non-session orders e.g. takeaway/delivery) ──
  @override
  Future<Either<Failure, void>> placeOrder(OrderEntity order) async {
    try {
      final index = _orders.indexWhere((o) => o.id == order.id);
      final eta = calculateOrderETA(order);
      final updated = order.copyWith(preparationTimeMinutes: eta);
      if (index >= 0) {
        _orders[index] = updated;
      } else {
        _orders.add(updated);
      }
      notifyListeners();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getCustomerOrders(
      String customerId) async {
    try {
      if (customerId == 'owner_feed') {
        return Right(List.from(_orders));
      }
      return Right(_orders.where((o) => o.customerId == customerId).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus(
      String orderId, String status) async {
    try {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        final order = _orders[index];
        String itemStatus = 'Waiting';
        if (status == 'Preparing') itemStatus = 'Preparing';
        else if (status == 'Ready to Serve' || status == 'Ready') itemStatus = 'Ready';
        else if (status == 'Served') itemStatus = 'Served';

        final updatedItems =
            order.items.map((i) => i.copyWith(status: itemStatus)).toList();
        _orders[index] = order.copyWith(
          status: status,
          items: updatedItems,
          updatedAt: DateTime.now(),
          servedAt: status == 'Served' ? DateTime.now() : order.servedAt,
          invoiceNumber: status == 'Served' && order.invoiceNumber == null
              ? 'INV-${order.id.replaceAll('ord_', '')}'
              : order.invoiceNumber,
        );
        notifyListeners();
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Session lifecycle ─────────────────────────────────────────────

  @override
  Future<Either<Failure, DiningSession>> getOrCreateActiveSession(
    String tableNumber,
    String restaurantId,
    String customerId,
    String customerName,
  ) async {
    try {
      // Find existing active session for this table + restaurant
      final activeIdx = _sessions.indexWhere((s) =>
          s.tableNumber == tableNumber &&
          s.restaurantId == restaurantId &&
          s.isActive);
      if (activeIdx >= 0) {
        return Right(_sessions[activeIdx]);
      }

      // Create a brand-new session
      final session = DiningSession(
        sessionId: _generateSessionId(),
        orderNumber: _generateOrderNumber(),
        tableNumber: tableNumber,
        restaurantId: restaurantId,
        customerId: customerId.isEmpty ? null : customerId,
        customerName: customerName,
        status: 'ordering',
        masterOrderId: null, // set when first appendItemsToSession is called
        orderVersion: 0,
        startTime: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _sessions.add(session);
      notifyListeners();
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DiningSession?>> getActiveSessionForTable(
    String tableNumber,
    String restaurantId,
  ) async {
    try {
      final idx = _sessions.indexWhere((s) =>
          s.tableNumber == tableNumber &&
          s.restaurantId == restaurantId &&
          s.isActive);
      return Right(idx >= 0 ? _sessions[idx] : null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DiningSession?>> getActiveSessionForCustomer(
      String customerId) async {
    try {
      final idx = _sessions.indexWhere(
          (s) => s.customerId == customerId && s.isActive);
      return Right(idx >= 0 ? _sessions[idx] : null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DiningSession>>> getSessionsForOwner(
      String restaurantId) async {
    try {
      return Right(
          _sessions.where((s) => s.restaurantId == restaurantId).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── THE CORE METHOD: appendItemsToSession ─────────────────────────
  /// Finds the active session, then either:
  ///   (a) Creates the FIRST master order for this session, or
  ///   (b) Appends new items to the EXISTING master order.
  ///
  /// This is the ONLY path for dine-in orders.
  /// A duplicate order is NEVER created.
  @override
  Future<Either<Failure, OrderEntity>> appendItemsToSession(
    String sessionId, {
    required List<CartItemEntity> newItems,
    required String modifiedBy,
    String? specialInstructions,
    double discount = 0.0,
    double coinDiscount = 0.0,
    double coinsRedeemed = 0.0,
  }) async {
    try {
      final sessionIdx =
          _sessions.indexWhere((s) => s.sessionId == sessionId);
      if (sessionIdx < 0) {
        return Left(ServerFailure('Session $sessionId not found.'));
      }

      final session = _sessions[sessionIdx];

      if (session.isFrozen) {
        return Left(
            ServerFailure('Order is frozen. Billing has been requested.'));
      }

      final batchId = _uuid.v4();
      final now = DateTime.now();
      final newVersion = session.orderVersion + 1;

      // New item IDs for kitchen highlighting
      final newItemIds = newItems.map((i) => i.itemId).toList();

      // ── Case A: No master order yet → create the first one ──────────
      if (session.masterOrderId == null) {
        final masterOrderId = 'ord_${_uuid.v4().substring(0, 8)}';

        // Map cart items to 'Waiting' status
        final mappedItems =
            newItems.map((i) => i.copyWith(status: 'Waiting')).toList();

        final subtotal = mappedItems.fold<double>(
            0, (sum, i) => sum + i.price * i.quantity);
        final tax = subtotal * 0.18;
        final total = (subtotal + tax - discount - coinDiscount)
            .clamp(0.0, double.infinity);

        final masterOrder = OrderEntity(
          id: masterOrderId,
          customerId: session.customerId ?? 'guest',
          restaurantId: session.restaurantId,
          items: mappedItems,
          subtotal: subtotal,
          tax: tax,
          deliveryFee: 0.0,
          discount: discount + coinDiscount,
          total: total,
          status: 'Received',
          deliveryAddress: 'Table ${session.tableNumber}',
          paymentMethod: 'pay_later',
          createdAt: now,
          updatedAt: now,
          tableNumber: session.tableNumber,
          customerName: session.customerName,
          specialInstructions: specialInstructions,
          diningSessionId: sessionId,
          orderNumber: session.orderNumber,
          newItemsSinceVersion: newItemIds,
          latestBatchId: batchId,
          kotNumber: 'KOT-001',
          coinsRedeemed: coinsRedeemed,
          coinDiscount: coinDiscount,
        );

        final eta = calculateOrderETA(masterOrder);
        final masterOrderWithEta =
            masterOrder.copyWith(preparationTimeMinutes: eta);
        _orders.add(masterOrderWithEta);

        // Update session with masterOrderId and bump version
        _sessions[sessionIdx] = session.copyWith(
          masterOrderId: masterOrderId,
          orderVersion: newVersion,
          updatedAt: now,
        );

        // Write history entries for each new item
        for (final item in newItems) {
          _orderHistory.add(OrderHistoryEntry(
            id: _uuid.v4(),
            sessionId: sessionId,
            version: newVersion,
            action: 'added',
            itemId: item.itemId,
            itemName: item.name,
            quantityDelta: item.quantity,
            newQuantity: item.quantity,
            itemPrice: item.price,
            modifiedBy: modifiedBy,
            timestamp: now,
            isNewKitchenBatch: true,
            batchId: batchId,
          ));
        }

        notifyListeners();
        return Right(masterOrderWithEta);
      }

      // ── Case B: Master order EXISTS → append new items ──────────────
      final masterOrderIdx =
          _orders.indexWhere((o) => o.id == session.masterOrderId);
      if (masterOrderIdx < 0) {
        return Left(ServerFailure('Master order not found for session.'));
      }

      final existing = _orders[masterOrderIdx];
      final existingItems = List<CartItemEntity>.from(existing.items);

      // Merge: if item already in the order, increase quantity;
      // otherwise add as a new item in 'Waiting' status.
      final List<CartItemEntity> mergedItems = List.from(existingItems);
      for (final newItem in newItems) {
        final existingIdx =
            mergedItems.indexWhere((i) => i.itemId == newItem.itemId);
        if (existingIdx >= 0) {
          final old = mergedItems[existingIdx];
          mergedItems[existingIdx] = old.copyWith(
            quantity: old.quantity + newItem.quantity,
            // Keep existing status (don't reset Preparing/Ready to Waiting)
          );
        } else {
          mergedItems.add(newItem.copyWith(status: 'Waiting'));
        }
      }

      final subtotal =
          mergedItems.fold<double>(0, (sum, i) => sum + i.price * i.quantity);
      final tax = subtotal * 0.18;
      final effectiveDiscount =
          existing.discount + discount + coinDiscount;
      final total =
          (subtotal + tax - effectiveDiscount).clamp(0.0, double.infinity);

      // Determine new kitchen status:
      // If cooking was already in progress, stay Preparing.
      // If brand-new items arrive, set back to Received so kitchen notices.
      String newStatus = existing.status;
      if (existing.status == 'Served' || existing.status == 'Ready to Serve') {
        newStatus = 'Received'; // Reopen for newly added items
      }

      final updatedOrder = existing.copyWith(
        items: mergedItems,
        subtotal: subtotal,
        tax: tax,
        discount: effectiveDiscount,
        total: total,
        status: newStatus,
        updatedAt: now,
        specialInstructions:
            specialInstructions ?? existing.specialInstructions,
        newItemsSinceVersion: newItemIds, // Only newly added item IDs
        latestBatchId: batchId,
        coinsRedeemed: (existing.coinsRedeemed ?? 0) + coinsRedeemed,
        coinDiscount: (existing.coinDiscount ?? 0) + coinDiscount,
      );

      final eta = calculateOrderETA(updatedOrder);
      final finalOrder =
          updatedOrder.copyWith(preparationTimeMinutes: eta);
      _orders[masterOrderIdx] = finalOrder;

      // Update session version
      _sessions[sessionIdx] = session.copyWith(
        orderVersion: newVersion,
        updatedAt: now,
      );

      // Write history entries
      for (final item in newItems) {
        // Find if this item already existed (for action label)
        final wasExisting =
            existingItems.any((i) => i.itemId == item.itemId);
        _orderHistory.add(OrderHistoryEntry(
          id: _uuid.v4(),
          sessionId: sessionId,
          version: newVersion,
          action: wasExisting ? 'updated' : 'added',
          itemId: item.itemId,
          itemName: item.name,
          quantityDelta: item.quantity,
          newQuantity: wasExisting
              ? (existingItems
                          .firstWhere((i) => i.itemId == item.itemId)
                          .quantity +
                      item.quantity)
              : item.quantity,
          itemPrice: item.price,
          modifiedBy: modifiedBy,
          timestamp: now,
          isNewKitchenBatch: true,
          batchId: batchId,
        ));
      }

      notifyListeners();
      return Right(finalOrder);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity?>> getMasterOrderForSession(
      String sessionId) async {
    try {
      final sessionIdx =
          _sessions.indexWhere((s) => s.sessionId == sessionId);
      if (sessionIdx < 0) return const Right(null);
      final session = _sessions[sessionIdx];
      if (session.masterOrderId == null) return const Right(null);
      final order = _orders.cast<OrderEntity?>().firstWhere(
            (o) => o?.id == session.masterOrderId,
            orElse: () => null,
          );
      return Right(order);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Item-level status ─────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> updateKOTItemStatus(
      String orderId, String itemId, String status) async {
    try {
      final orderIdx = _orders.indexWhere((o) => o.id == orderId);
      if (orderIdx >= 0) {
        final order = _orders[orderIdx];
        final updatedItems = order.items.map((item) {
          if (item.itemId == itemId) return item.copyWith(status: status);
          return item;
        }).toList();

        final statuses = updatedItems.map((i) => i.status).toSet();
        String kotStatus = order.status;
        if (statuses.length == 1) {
          final s = statuses.first;
          if (s == 'Preparing') kotStatus = 'Preparing';
          else if (s == 'Ready') kotStatus = 'Ready to Serve';
          else if (s == 'Served') kotStatus = 'Served';
        } else {
          if (statuses.contains('Preparing')) kotStatus = 'Preparing';
          else if (statuses.contains('Ready') &&
              !statuses.contains('Preparing') &&
              !statuses.contains('Waiting')) {
            kotStatus = 'Ready to Serve';
          }
        }

        // When a new batch arrives, clear only the new-items highlight
        // (the chef has now seen those items since we're updating statuses)
        _orders[orderIdx] = order.copyWith(
          items: updatedItems,
          status: kotStatus,
          updatedAt: DateTime.now(),
          servedAt:
              kotStatus == 'Served' ? DateTime.now() : order.servedAt,
          // Clear new items highlight once chef starts interacting
          newItemsSinceVersion: const [],
        );
        notifyListeners();
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateKOTDetails(String orderId,
      {double? ownerDelay, String? priority}) async {
    try {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        var order = _orders[index];
        order = order.copyWith(
          ownerDelayMinutes: ownerDelay ?? order.ownerDelayMinutes,
          priority: priority ?? order.priority,
        );
        _orders[index] =
            order.copyWith(preparationTimeMinutes: calculateOrderETA(order));
        notifyListeners();
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Billing lifecycle ─────────────────────────────────────────────
  @override
  Future<Either<Failure, void>> freezeOrderForBilling(
      String sessionId) async {
    try {
      final sessionIdx =
          _sessions.indexWhere((s) => s.sessionId == sessionId);
      if (sessionIdx >= 0) {
        _sessions[sessionIdx] = _sessions[sessionIdx].copyWith(
          status: 'billing_ready',
          updatedAt: DateTime.now(),
        );
        // Freeze the master order
        if (_sessions[sessionIdx].masterOrderId != null) {
          final orderIdx = _orders
              .indexWhere((o) => o.id == _sessions[sessionIdx].masterOrderId);
          if (orderIdx >= 0) {
            _orders[orderIdx] = _orders[orderIdx].copyWith(isFrozen: true);
          }
        }
        notifyListeners();
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> closeSession(
    String sessionId, {
    required String paymentMethod,
    double discount = 0.0,
    double coinsRedeemed = 0.0,
    double coinsEarned = 0.0,
  }) async {
    try {
      final sessionIdx =
          _sessions.indexWhere((s) => s.sessionId == sessionId);
      if (sessionIdx >= 0) {
        final session = _sessions[sessionIdx];

        // Compute totals from the single master order
        double subtotal = 0.0;
        double tax = 0.0;

        if (session.masterOrderId != null) {
          final orderIdx =
              _orders.indexWhere((o) => o.id == session.masterOrderId);
          if (orderIdx >= 0) {
            final masterOrder = _orders[orderIdx];
            subtotal = masterOrder.subtotal;
            tax = masterOrder.tax;

            // Mark order as paid and served
            _orders[orderIdx] = masterOrder.copyWith(
              paymentStatus: 'paid',
              status: 'Served',
              servedAt: masterOrder.servedAt ?? DateTime.now(),
              isFrozen: true,
              invoiceNumber:
                  'INV-${sessionId.replaceAll('SID-', '')}',
            );
          }
        }

        final coinsDiscountVal = coinsRedeemed / 100.0;
        final grandTotal =
            (subtotal + tax - discount - coinsDiscountVal)
                .clamp(0.0, double.infinity);

        _sessions[sessionIdx] = session.copyWith(
          status: 'session_closed',
          paymentStatus: 'paid',
          paymentMethod: paymentMethod,
          subtotal: subtotal,
          tax: tax,
          discount: discount,
          coinDiscount: coinsDiscountVal,
          grandTotal: grandTotal,
          invoiceId: 'INV-${sessionId.replaceAll('SID-', '')}',
          coinsRedeemed: coinsRedeemed,
          coinsEarned: coinsEarned,
          endTime: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        notifyListeners();
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Order history ─────────────────────────────────────────────────
  @override
  Future<Either<Failure, List<OrderHistoryEntry>>> getOrderHistoryForSession(
      String sessionId) async {
    try {
      final history = _orderHistory
          .where((h) => h.sessionId == sessionId)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Legacy session methods (kept for backward compat)
  Future<Either<Failure, List<OrderEntity>>> getKOTsForSession(
      String sessionId) async {
    try {
      return Right(
          _orders.where((o) => o.diningSessionId == sessionId).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
