import 'package:equatable/equatable.dart';

class RewardOfferEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final double costInCoins;
  final String category; // 'beverage', 'dessert', 'discount', 'deal'
  final String imageUrl;
  final bool isActive;
  final String promoCode;

  const RewardOfferEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.costInCoins,
    required this.category,
    required this.imageUrl,
    required this.isActive,
    required this.promoCode,
  });

  @override
  List<Object?> get props => [id, title, description, costInCoins, category, imageUrl, isActive, promoCode];
}
