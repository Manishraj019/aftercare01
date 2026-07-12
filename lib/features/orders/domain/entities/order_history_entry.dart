import 'package:equatable/equatable.dart';

/// Represents one versioned change to an order within a dining session.
/// Every item addition, removal, or update is stored here for a complete audit trail.
class OrderHistoryEntry extends Equatable {
  final String id;
  final String sessionId;

  /// Version number of the order after this change was applied
  final int version;

  /// 'added', 'removed', 'updated', 'instruction_changed'
  final String action;

  final String itemId;
  final String itemName;

  /// Quantity delta (positive = added, negative = removed)
  final int quantityDelta;

  /// The quantity after this change
  final int newQuantity;

  final double itemPrice;

  /// 'customer', 'owner', 'staff'
  final String modifiedBy;

  final DateTime timestamp;

  /// True when this is the first entry of a new order batch sent to the kitchen
  /// The kitchen will highlight all items in the same batch
  final bool isNewKitchenBatch;

  /// An opaque batch key — all entries with the same batchId were ordered together
  final String batchId;

  const OrderHistoryEntry({
    required this.id,
    required this.sessionId,
    required this.version,
    required this.action,
    required this.itemId,
    required this.itemName,
    required this.quantityDelta,
    required this.newQuantity,
    required this.itemPrice,
    required this.modifiedBy,
    required this.timestamp,
    this.isNewKitchenBatch = false,
    required this.batchId,
  });

  @override
  List<Object?> get props => [
        id,
        sessionId,
        version,
        action,
        itemId,
        itemName,
        quantityDelta,
        newQuantity,
        itemPrice,
        modifiedBy,
        timestamp,
        isNewKitchenBatch,
        batchId,
      ];
}
