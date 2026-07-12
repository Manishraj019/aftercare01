import 'package:equatable/equatable.dart';

class CartItemEntity extends Equatable {
  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  // Food Customizations
  final String? notes;
  final String? spiceLevel;
  final List<String>? addOns;

  // Item Level Status
  final String status; // 'Waiting', 'Preparing', 'Ready', 'Served'

  const CartItemEntity({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.notes,
    this.spiceLevel,
    this.addOns,
    this.status = 'Waiting',
  });

  double get total => price * quantity;

  CartItemEntity copyWith({
    int? quantity,
    String? notes,
    String? spiceLevel,
    List<String>? addOns,
    String? status,
  }) {
    return CartItemEntity(
      itemId: itemId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
      notes: notes ?? this.notes,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      addOns: addOns ?? this.addOns,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [itemId, name, price, quantity, imageUrl, notes, spiceLevel, addOns, status];
}
