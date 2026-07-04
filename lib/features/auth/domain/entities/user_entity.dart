import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? phoneNumber;
  final String role; // 'customer', 'owner', 'admin'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        phoneNumber,
        role,
        isActive,
        createdAt,
        updatedAt,
      ];
}
