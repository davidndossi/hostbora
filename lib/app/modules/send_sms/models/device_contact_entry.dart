class DeviceContactEntry {
  const DeviceContactEntry({
    required this.contactId,
    required this.displayName,
    required this.phone,
  });

  final String contactId;
  final String displayName;
  final String phone;

  String get selectionKey => '$contactId|$phone';
}
