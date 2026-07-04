import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  const CartItemEntity({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  double get total => price * quantity;

  CartItemEntity copyWith({
    int? quantity,
  }) {
    return CartItemEntity(
      itemId: itemId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
    );
  }

  @override
  List<Object?> get props => [itemId, name, price, quantity, imageUrl];
}
