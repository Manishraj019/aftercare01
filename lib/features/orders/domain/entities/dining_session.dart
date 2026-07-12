import 'package:equatable/equatable.dart';

/// Session Status lifecycle:
/// ordering → accepted → cooking → ready → served → billing_ready → payment_completed → session_closed
class DiningSession extends Equatable {
  /// Unique session ID, e.g. 'SID-7HG82K91' — NEVER changes for the lifetime of a dining session
  final String sessionId;

  /// Human-readable order number, e.g. '#A1025' — assigned once, NEVER changes
  final String orderNumber;

  final String tableNumber;
  final String restaurantId;

  /// Optional — null for guest customers
  final String? customerId;
  final String customerName;

  /// Full lifecycle status
  final String status;

  /// The one and only master OrderEntity ID for this session (null until first order is placed)
  final String? masterOrderId;

  /// Increments every time items are added/removed/updated
  final int orderVersion;

  final DateTime startTime;
  final DateTime? endTime;
  final DateTime updatedAt;

  // ── Billing Fields ──────────────────────────────────────────────
  final double subtotal;
  final double tax;
  final double discount;
  final double couponDiscount;
  final double coinDiscount;
  final double serviceCharge;
  final double grandTotal;
  final String paymentStatus; // 'unpaid', 'paid'
  final String? paymentMethod; // 'upi', 'card', 'cash', 'wallet', 'net_banking'
  final String? invoiceId;
  final double coinsRedeemed;
  final double coinsEarned;

  const DiningSession({
    required this.sessionId,
    required this.orderNumber,
    required this.tableNumber,
    required this.restaurantId,
    this.customerId,
    required this.customerName,
    required this.status,
    this.masterOrderId,
    this.orderVersion = 0,
    required this.startTime,
    this.endTime,
    required this.updatedAt,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    this.couponDiscount = 0.0,
    this.coinDiscount = 0.0,
    this.serviceCharge = 0.0,
    this.grandTotal = 0.0,
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.invoiceId,
    this.coinsRedeemed = 0.0,
    this.coinsEarned = 0.0,
  });

  /// Whether this session is still accepting orders (not yet in billing/closed state)
  bool get isActive =>
      status != 'payment_completed' && status != 'session_closed';

  /// Whether this session is frozen and no more item changes are allowed
  bool get isFrozen =>
      status == 'billing_ready' ||
      status == 'payment_completed' ||
      status == 'session_closed';

  DiningSession copyWith({
    String? sessionId,
    String? orderNumber,
    String? tableNumber,
    String? restaurantId,
    String? customerId,
    String? customerName,
    String? status,
    String? masterOrderId,
    int? orderVersion,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? updatedAt,
    double? subtotal,
    double? tax,
    double? discount,
    double? couponDiscount,
    double? coinDiscount,
    double? serviceCharge,
    double? grandTotal,
    String? paymentStatus,
    String? paymentMethod,
    String? invoiceId,
    double? coinsRedeemed,
    double? coinsEarned,
  }) {
    return DiningSession(
      sessionId: sessionId ?? this.sessionId,
      orderNumber: orderNumber ?? this.orderNumber,
      tableNumber: tableNumber ?? this.tableNumber,
      restaurantId: restaurantId ?? this.restaurantId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      masterOrderId: masterOrderId ?? this.masterOrderId,
      orderVersion: orderVersion ?? this.orderVersion,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      updatedAt: updatedAt ?? this.updatedAt,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      coinDiscount: coinDiscount ?? this.coinDiscount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      invoiceId: invoiceId ?? this.invoiceId,
      coinsRedeemed: coinsRedeemed ?? this.coinsRedeemed,
      coinsEarned: coinsEarned ?? this.coinsEarned,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        orderNumber,
        tableNumber,
        restaurantId,
        customerId,
        customerName,
        status,
        masterOrderId,
        orderVersion,
        startTime,
        endTime,
        updatedAt,
        subtotal,
        tax,
        discount,
        couponDiscount,
        coinDiscount,
        serviceCharge,
        grandTotal,
        paymentStatus,
        paymentMethod,
        invoiceId,
        coinsRedeemed,
        coinsEarned,
      ];
}
