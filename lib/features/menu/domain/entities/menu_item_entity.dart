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
  final bool isBestSeller;
  final double preparationTimeMinutes;

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
    this.isBestSeller = false,
    this.preparationTimeMinutes = 10.0,
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
        isBestSeller,
        preparationTimeMinutes,
      ];
}
