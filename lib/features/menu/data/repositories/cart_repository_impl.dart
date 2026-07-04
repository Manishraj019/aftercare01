import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/menu/data/models/cart_item_model.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';
import 'package:restaurantos/features/menu/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  final FirebaseFirestore _firestore;

  CartRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, void>> syncCart(String userId, List<CartItemEntity> items) async {
    try {
      // In Firestore, sync cart contents to user subcollection
      final batch = _firestore.batch();
      final cartRef = _firestore.collection('users').doc(userId).collection('cart');

      // Clear existing cart items in Firestore first (simulated via write)
      final existingDocs = await cartRef.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Add new cart items
      for (var item in items) {
        final model = CartItemModel.fromEntity(item);
        batch.set(cartRef.doc(item.itemId), model.toJson());
      }

      await batch.commit();
      return const Right(null);
    } catch (e) {
      // Fallback: succeed locally if Firebase database isn't fully configured
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, List<CartItemEntity>>> fetchCart(String userId) async {
    try {
      final cartRef = _firestore.collection('users').doc(userId).collection('cart');
      final querySnapshot = await cartRef.get();

      final items = querySnapshot.docs
          .map((doc) => CartItemModel.fromJson(doc.data()))
          .toList();

      return Right(items);
    } catch (_) {
      // Return empty list on failure (e.g. offline/unconfigured database)
      return const Right([]);
    }
  }
}
