class InventoryItemRequest {
  const InventoryItemRequest({
    this.clientItemId,
    this.propertyRef,
    this.propertyLabel,
    this.apartmentUnitId,
    this.apartmentUnitName,
    required this.name,
    required this.category,
    required this.quantity,
    this.reorderLevel = 0,
    this.condition = 'Good',
    this.locationNote,
    this.purchaseValue,
    this.currency,
  });

  final String? clientItemId;
  final String? propertyRef;
  final String? propertyLabel;
  final String? apartmentUnitId;
  final String? apartmentUnitName;
  final String name;
  final String category;
  final int quantity;
  final int reorderLevel;
  final String condition;
  final String? locationNote;
  final double? purchaseValue;
  final String? currency;

  Map<String, dynamic> toJson() => {
        if (clientItemId != null && clientItemId!.isNotEmpty)
          'clientItemId': clientItemId,
        if (propertyRef != null && propertyRef!.isNotEmpty)
          'propertyRef': propertyRef,
        if (propertyLabel != null && propertyLabel!.isNotEmpty)
          'propertyLabel': propertyLabel,
        if (apartmentUnitId != null && apartmentUnitId!.isNotEmpty)
          'apartmentUnitId': apartmentUnitId,
        if (apartmentUnitName != null && apartmentUnitName!.isNotEmpty)
          'apartmentUnitName': apartmentUnitName,
        'name': name,
        'category': category,
        'quantity': quantity,
        'reorderLevel': reorderLevel,
        'condition': condition,
        if (locationNote != null && locationNote!.isNotEmpty)
          'locationNote': locationNote,
        if (purchaseValue != null) 'purchaseValue': purchaseValue,
        'currency': () {
          final code = (currency ?? 'TZS').trim().toUpperCase();
          return code.isEmpty ? 'TZS' : code;
        }(),
      };
}

class InventoryMovementRequest {
  const InventoryMovementRequest({
    this.clientMovementId,
    required this.movementType,
    required this.quantityDelta,
    this.notes,
  });

  final String? clientMovementId;
  final String movementType;
  final int quantityDelta;
  final String? notes;

  Map<String, dynamic> toJson() => {
        if (clientMovementId != null && clientMovementId!.isNotEmpty)
          'clientMovementId': clientMovementId,
        'movementType': movementType,
        'quantityDelta': quantityDelta,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
