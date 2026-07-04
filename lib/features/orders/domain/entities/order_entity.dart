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
  final String status; // 'placed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled'
  final String deliveryAddress;
  final String paymentMethod; // 'upi', 'card', 'wallet'
  final DateTime createdAt;
  final DateTime updatedAt;

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
  });

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
      ];
}
