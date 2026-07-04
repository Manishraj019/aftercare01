import 'package:equatable/equatable.dart';

class RestaurantEntity extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final String address;
  final bool isActive;
  final DateTime createdAt;

  const RestaurantEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.address,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        ownerId,
        address,
        isActive,
        createdAt,
      ];
}
