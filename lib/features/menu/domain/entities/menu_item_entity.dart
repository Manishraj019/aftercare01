import 'package:equatable/equatable.dart';

class MenuItemEntity extends Equatable {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool isVegetarian;
  final bool isAvailable;
  final String imageUrl;

  const MenuItemEntity({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.isVegetarian,
    this.isAvailable = true,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        name,
        description,
        price,
        category,
        isVegetarian,
        isAvailable,
        imageUrl,
      ];
}
