import 'package:dartz/dartz.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/domain/entities/dining_session.dart';
import 'package:restaurantos/features/orders/domain/entities/order_history_entry.dart';

abstract class OrderRepository {
  // ── Legacy / KDS helpers ────────────────────────────────────────
  Future<Either<Failure, void>> placeOrder(OrderEntity order);
  Future<Either<Failure, List<OrderEntity>>> getCustomerOrders(String customerId);
  Future<Either<Failure, void>> updateOrderStatus(String orderId, String status);

  // ── Session lifecycle ───────────────────────────────────────────

  /// Find an existing active session for the table, or create a brand-new one.
  /// Returns the session with its immutable orderNumber and sessionId.
  Future<Either<Failure, DiningSession>> getOrCreateActiveSession(
      String tableNumber, String restaurantId, String customerId, String customerName);

  /// Look up an active session for a table without creating one.
  Future<Either<Failure, DiningSession?>> getActiveSessionForTable(
      String tableNumber, String restaurantId);

  /// Look up an active session for a customer.
  Future<Either<Failure, DiningSession?>> getActiveSessionForCustomer(
      String customerId);

  /// Returns all sessions for an owner's restaurant (for dashboard grouping).
  Future<Either<Failure, List<DiningSession>>> getSessionsForOwner(
      String restaurantId);

  // ── Core persistent-order operations ───────────────────────────

  /// THE KEY METHOD: Appends [newItems] to the session's single master order.
  ///
  /// - If no master order exists yet → creates one (version 1).
  /// - If a master order already exists → merges items, bumps orderVersion,
  ///   records history entries, and marks the new items in [newItemsSinceVersion].
  ///
  /// [modifiedBy] is 'customer', 'owner', or 'staff'.
  Future<Either<Failure, OrderEntity>> appendItemsToSession(
    String sessionId, {
    required List<CartItemEntity> newItems,
    required String modifiedBy,
    String? specialInstructions,
    double discount = 0.0,
    double coinDiscount = 0.0,
    double coinsRedeemed = 0.0,
  });

  /// Returns the single master OrderEntity for the session.
  Future<Either<Failure, OrderEntity?>> getMasterOrderForSession(
      String sessionId);

  // ── Item-level operations ───────────────────────────────────────

  Future<Either<Failure, void>> updateKOTItemStatus(
      String orderId, String itemId, String status);

  Future<Either<Failure, void>> updateKOTDetails(String orderId,
      {double? ownerDelay, String? priority});

  // ── Billing lifecycle ───────────────────────────────────────────

  /// Freezes the session: no more item modifications allowed, status → billing_ready.
  Future<Either<Failure, void>> freezeOrderForBilling(String sessionId);

  /// Completes payment and closes the session. Releases the table.
  Future<Either<Failure, void>> closeSession(
    String sessionId, {
    required String paymentMethod,
    double discount = 0.0,
    double coinsRedeemed = 0.0,
    double coinsEarned = 0.0,
  });

  // ── Order History / Versioning ──────────────────────────────────

  /// Returns the full ordered history of changes for a session.
  Future<Either<Failure, List<OrderHistoryEntry>>> getOrderHistoryForSession(
      String sessionId);

  // ── Kitchen Load ────────────────────────────────────────────────
  String getKitchenLoadStatus();
  void setKitchenLoadStatus(String status);
}
