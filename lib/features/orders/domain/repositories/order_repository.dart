import 'package:dartz/dartz.dart';
import 'package:restaurantos/core/errors/failures.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';

abstract class OrderRepository {
  Future<Either<Failure, void>> placeOrder(OrderEntity order);
  Future<Either<Failure, List<OrderEntity>>> getCustomerOrders(String customerId);
  Future<Either<Failure, void>> updateOrderStatus(String orderId, String status);
}
