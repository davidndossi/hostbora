/// Tenant or BnB guest row for the Send SMS recipient picker.
class MessagingContact {
  const MessagingContact({
    required this.key,
    required this.label,
    required this.phone,
    required this.kind,
    this.subtitle = '',
  });

  final String key;
  final String label;
  final String phone;
  final String subtitle;

  /// `tenant` or `guest`.
  final String kind;
}
