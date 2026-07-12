import 'package:equatable/equatable.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';

class OrderEntity extends Equatable {
  final String id;
  final String customerId;
  final String restaurantId;
  final List<CartItemEntity> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;
  final String status; // 'Received', 'Preparing', 'Ready to Serve', 'Served'
  final String deliveryAddress;
  final String paymentMethod; // 'upi', 'card', 'wallet', 'cash', 'net_banking'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Restaurant-specific fields
  final String? tableNumber;
  final String? customerName;
  final String? specialInstructions;
  final String paymentStatus; // 'unpaid', 'paid'
  final String? invoiceNumber;
  final double? gst;
  final double? serviceTax;
  final DateTime? servedAt;
  final double preparationTimeMinutes;
  final String? diningSessionId;
  final String? kotNumber;
  final double ownerDelayMinutes;
  final String priority; // 'normal', 'high'
  final DateTime? actualStartTime;
  final double chefDelayMinutes;

  // Loyalty Reward fields
  final double? coinsRedeemed;
  final double? coinsEarned;
  final double? coinDiscount;

  // ── Persistent Session fields ────────────────────────────────────
  /// Human-readable order number e.g. '#A1025' — same as DiningSession.orderNumber
  /// NEVER changes for the lifetime of the dining session.
  final String? orderNumber;

  /// Item IDs that were added in the most recent append batch.
  /// Kitchen uses this to highlight newly added items.
  /// Cleared after the chef acknowledges the new batch.
  final List<String> newItemsSinceVersion;

  /// The batchId of the most recent kitchen-notify batch (for grouping highlights)
  final String? latestBatchId;

  /// When true, no further item modifications are allowed.
  /// Set to true when the customer requests the bill (billing_ready status).
  final bool isFrozen;

  const OrderEntity({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    this.discount = 0.0,
    required this.total,
    required this.status,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.tableNumber,
    this.customerName,
    this.specialInstructions,
    this.paymentStatus = 'unpaid',
    this.invoiceNumber,
    this.gst,
    this.serviceTax,
    this.servedAt,
    this.preparationTimeMinutes = 15.0,
    this.diningSessionId,
    this.kotNumber,
    this.ownerDelayMinutes = 0.0,
    this.priority = 'normal',
    this.coinsRedeemed = 0.0,
    this.coinsEarned = 0.0,
    this.coinDiscount = 0.0,
    this.actualStartTime,
    this.chefDelayMinutes = 0.0,
    this.orderNumber,
    this.newItemsSinceVersion = const [],
    this.latestBatchId,
    this.isFrozen = false,
  });

  OrderEntity copyWith({
    String? id,
    String? customerId,
    String? restaurantId,
    List<CartItemEntity>? items,
    double? subtotal,
    double? tax,
    double? deliveryFee,
    double? discount,
    double? total,
    String? status,
    String? deliveryAddress,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tableNumber,
    String? customerName,
    String? specialInstructions,
    String? paymentStatus,
    String? invoiceNumber,
    double? gst,
    double? serviceTax,
    DateTime? servedAt,
    double? preparationTimeMinutes,
    String? diningSessionId,
    String? kotNumber,
    double? ownerDelayMinutes,
    String? priority,
    double? coinsRedeemed,
    double? coinsEarned,
    double? coinDiscount,
    DateTime? actualStartTime,
    double? chefDelayMinutes,
    String? orderNumber,
    List<String>? newItemsSinceVersion,
    String? latestBatchId,
    bool? isFrozen,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      restaurantId: restaurantId ?? this.restaurantId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tableNumber: tableNumber ?? this.tableNumber,
      customerName: customerName ?? this.customerName,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      gst: gst ?? this.gst,
      serviceTax: serviceTax ?? this.serviceTax,
      servedAt: servedAt ?? this.servedAt,
      preparationTimeMinutes:
          preparationTimeMinutes ?? this.preparationTimeMinutes,
      diningSessionId: diningSessionId ?? this.diningSessionId,
      kotNumber: kotNumber ?? this.kotNumber,
      ownerDelayMinutes: ownerDelayMinutes ?? this.ownerDelayMinutes,
      priority: priority ?? this.priority,
      coinsRedeemed: coinsRedeemed ?? this.coinsRedeemed,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      coinDiscount: coinDiscount ?? this.coinDiscount,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      chefDelayMinutes: chefDelayMinutes ?? this.chefDelayMinutes,
      orderNumber: orderNumber ?? this.orderNumber,
      newItemsSinceVersion: newItemsSinceVersion ?? this.newItemsSinceVersion,
      latestBatchId: latestBatchId ?? this.latestBatchId,
      isFrozen: isFrozen ?? this.isFrozen,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        restaurantId,
        items,
        subtotal,
        tax,
        deliveryFee,
        discount,
        total,
        status,
        deliveryAddress,
        paymentMethod,
        createdAt,
        updatedAt,
        tableNumber,
        customerName,
        specialInstructions,
        paymentStatus,
        invoiceNumber,
        gst,
        serviceTax,
        servedAt,
        preparationTimeMinutes,
        diningSessionId,
        kotNumber,
        ownerDelayMinutes,
        priority,
        coinsRedeemed,
        coinsEarned,
        coinDiscount,
        actualStartTime,
        chefDelayMinutes,
        orderNumber,
        newItemsSinceVersion,
        latestBatchId,
        isFrozen,
      ];
}
