/// Request body for POST /api/client-events.
class RecordClientEventRequest {
  RecordClientEventRequest({
    required this.eventType,
    required this.workspace,
    this.phoneNumber = '',
    this.clientName = '',
    this.propertyRef = '',
    this.propertyLabel = '',
    this.unitLabel = '',
    this.amountTsh = 0,
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.metadataJson = '{}',
  });

  final String eventType;
  final String workspace;
  final String phoneNumber;
  final String clientName;
  final String propertyRef;
  final String propertyLabel;
  final String unitLabel;
  final int amountTsh;
  final int balanceBefore;
  final int balanceAfter;
  final String metadataJson;

  Map<String, dynamic> toJson() => {
        'eventType': eventType,
        'workspace': workspace,
        if (phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
        if (clientName.isNotEmpty) 'clientName': clientName,
        if (propertyRef.isNotEmpty) 'propertyRef': propertyRef,
        if (propertyLabel.isNotEmpty) 'propertyLabel': propertyLabel,
        if (unitLabel.isNotEmpty) 'unitLabel': unitLabel,
        'amountTsh': amountTsh,
        'balanceBefore': balanceBefore,
        'balanceAfter': balanceAfter,
        'metadataJson': metadataJson,
      };
}
