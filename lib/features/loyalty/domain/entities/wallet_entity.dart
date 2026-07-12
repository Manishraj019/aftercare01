import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String id;
  final String customerId;
  final double balance;
  final double lifetimeEarned;
  final double totalRedeemed;
  final String membershipLevel; // 'Silver', 'Gold', 'Platinum'

  const WalletEntity({
    required this.id,
    required this.customerId,
    required this.balance,
    required this.lifetimeEarned,
    required this.totalRedeemed,
    required this.membershipLevel,
  });

  WalletEntity copyWith({
    String? id,
    String? customerId,
    double? balance,
    double? lifetimeEarned,
    double? totalRedeemed,
    String? membershipLevel,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      balance: balance ?? this.balance,
      lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
      totalRedeemed: totalRedeemed ?? this.totalRedeemed,
      membershipLevel: membershipLevel ?? this.membershipLevel,
    );
  }

  @override
  List<Object?> get props => [id, customerId, balance, lifetimeEarned, totalRedeemed, membershipLevel];
}

class WalletTransaction extends Equatable {
  final String id;
  final double amount;
  final String type; // 'earn', 'redeem', 'bonus'
  final String description;
  final DateTime createdAt;
  final String? restaurantName;
  final String? orderId;

  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    this.restaurantName,
    this.orderId,
  });

  @override
  List<Object?> get props => [id, amount, type, description, createdAt, restaurantName, orderId];
}
