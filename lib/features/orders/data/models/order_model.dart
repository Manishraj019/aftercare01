import 'package:restaurantos/features/menu/data/models/cart_item_model.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.customerId,
    required super.restaurantId,
    required super.items,
    required super.subtotal,
    required super.tax,
    required super.deliveryFee,
    super.discount,
    required super.total,
    required super.status,
    required super.deliveryAddress,
    required super.paymentMethod,
    required super.createdAt,
    required super.updatedAt,
    super.tableNumber,
    super.customerName,
    super.specialInstructions,
    super.paymentStatus,
    super.invoiceNumber,
    super.gst,
    super.serviceTax,
    super.servedAt,
    super.preparationTimeMinutes,
    super.diningSessionId,
    super.kotNumber,
    super.ownerDelayMinutes,
    super.priority,
    super.coinsRedeemed,
    super.coinsEarned,
    super.coinDiscount,
    super.actualStartTime,
    super.chefDelayMinutes,
    super.orderNumber,
    super.newItemsSinceVersion,
    super.latestBatchId,
    super.isFrozen,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is String) {
        return DateTime.parse(value);
      } else {
        return DateTime.now();
      }
    }

    return OrderModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      restaurantId: json['restaurantId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      deliveryAddress: json['deliveryAddress'] as String,
      paymentMethod: json['paymentMethod'] as String,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      tableNumber: json['tableNumber'] as String?,
      customerName: json['customerName'] as String?,
      diningSessionId: json['diningSessionId'] as String?,
      kotNumber: json['kotNumber'] as String?,
      orderNumber: json['orderNumber'] as String?,
      newItemsSinceVersion: (json['newItemsSinceVersion'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      latestBatchId: json['latestBatchId'] as String?,
      isFrozen: json['isFrozen'] as bool? ?? false,
      paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
      coinsRedeemed: (json['coinsRedeemed'] as num?)?.toDouble() ?? 0.0,
      coinsEarned: (json['coinsEarned'] as num?)?.toDouble() ?? 0.0,
      coinDiscount: (json['coinDiscount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'restaurantId': restaurantId,
      'items': items
          .map((item) => CartItemModel.fromEntity(item).toJson())
          .toList(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tableNumber': tableNumber,
      'customerName': customerName,
      'diningSessionId': diningSessionId,
      'kotNumber': kotNumber,
      'orderNumber': orderNumber,
      'newItemsSinceVersion': newItemsSinceVersion,
      'latestBatchId': latestBatchId,
      'isFrozen': isFrozen,
      'paymentStatus': paymentStatus,
      'coinsRedeemed': coinsRedeemed,
      'coinsEarned': coinsEarned,
      'coinDiscount': coinDiscount,
    };
  }

  factory OrderModel.fromEntity(OrderEntity entity) {
    return OrderModel(
      id: entity.id,
      customerId: entity.customerId,
      restaurantId: entity.restaurantId,
      items: entity.items,
      subtotal: entity.subtotal,
      tax: entity.tax,
      deliveryFee: entity.deliveryFee,
      discount: entity.discount,
      total: entity.total,
      status: entity.status,
      deliveryAddress: entity.deliveryAddress,
      paymentMethod: entity.paymentMethod,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      tableNumber: entity.tableNumber,
      customerName: entity.customerName,
      specialInstructions: entity.specialInstructions,
      paymentStatus: entity.paymentStatus,
      invoiceNumber: entity.invoiceNumber,
      gst: entity.gst,
      serviceTax: entity.serviceTax,
      servedAt: entity.servedAt,
      preparationTimeMinutes: entity.preparationTimeMinutes,
      diningSessionId: entity.diningSessionId,
      kotNumber: entity.kotNumber,
      ownerDelayMinutes: entity.ownerDelayMinutes,
      priority: entity.priority,
      coinsRedeemed: entity.coinsRedeemed,
      coinsEarned: entity.coinsEarned,
      coinDiscount: entity.coinDiscount,
      actualStartTime: entity.actualStartTime,
      chefDelayMinutes: entity.chefDelayMinutes,
      orderNumber: entity.orderNumber,
      newItemsSinceVersion: entity.newItemsSinceVersion,
      latestBatchId: entity.latestBatchId,
      isFrozen: entity.isFrozen,
    );
  }
}
