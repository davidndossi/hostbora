/// Request body for POST /api/staff and PUT /api/staff/:id.
class StaffRequest {
  StaffRequest({
    required this.name,
    required this.role,
    required this.salary,
    required this.salaryFrequency,
    this.phone,
    this.notes,
    this.propertyName,
    this.propertyRef,
    this.startDate,
    this.status = 'active',
    this.payDayLabel,
    this.id,
    this.permissionRole,
    this.permissions,
    this.allProperties,
    this.propertyRefs,
  });

  final String name;
  final String role;
  final double salary;

  /// e.g. monthly, hourly, per_work
  final String salaryFrequency;
  final String? phone;
  final String? notes;
  final String? propertyName;
  final String? propertyRef;

  /// ISO date yyyy-MM-dd
  final String? startDate;
  final String status;

  /// Local-only pay day (also appended to [notes] for the API).
  final String? payDayLabel;

  /// Set for updates / offline sync.
  final String? id;

  /// Checklist role key: cleaner, caretaker, front_desk, accountant, manager.
  final String? permissionRole;
  final List<String>? permissions;
  final bool? allProperties;
  final List<String>? propertyRefs;

  Map<String, dynamic> toApiJson() {
    final combinedNotes = _combinedNotes();
    final body = <String, dynamic>{
      'name': name.trim(),
      'role': role.trim(),
      'salary': salary,
      'salaryFrequency': salaryFrequency.trim(),
      'status': status.trim().isEmpty ? 'active' : status.trim(),
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      if (combinedNotes.isNotEmpty) 'notes': combinedNotes,
      if (propertyName != null && propertyName!.trim().isNotEmpty)
        'propertyName': propertyName!.trim(),
      if (propertyRef != null && propertyRef!.trim().isNotEmpty)
        'propertyRef': propertyRef!.trim(),
      if (startDate != null && startDate!.trim().isNotEmpty)
        'startDate': startDate!.trim(),
      // Legacy aliases used by older app builds / local sync payloads.
      'jobTitle': role.trim(),
      'amountValue': salary,
      'paymentType': salaryFrequency.trim(),
      if (payDayLabel != null && payDayLabel!.trim().isNotEmpty)
        'payDayLabel': payDayLabel!.trim(),
      if (id != null && id!.trim().isNotEmpty) 'id': id!.trim(),
      if (permissionRole != null && permissionRole!.trim().isNotEmpty)
        'permissionRole': permissionRole!.trim(),
      if (permissions != null) 'permissions': permissions,
      if (allProperties != null) 'allProperties': allProperties,
      if (propertyRefs != null) 'propertyRefs': propertyRefs,
    };
    _mirrorSnakeCase(body);
    return body;
  }

  static void _mirrorSnakeCase(Map<String, dynamic> body) {
    void mirror(String camel, String snake) {
      if (body.containsKey(camel)) body[snake] = body[camel];
    }

    mirror('propertyName', 'property_name');
    mirror('propertyRef', 'property_ref');
    mirror('salaryFrequency', 'salary_frequency');
    mirror('startDate', 'start_date');
  }

  static List<String>? _stringList(dynamic raw) {
    if (raw is! List) return null;
    return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  }

  String _combinedNotes() {
    final parts = <String>[];
    final userNotes = notes?.trim() ?? '';
    if (userNotes.isNotEmpty) parts.add(userNotes);
    final payDay = payDayLabel?.trim() ?? '';
    if (payDay.isNotEmpty) parts.add('Pay day: $payDay');
    return parts.join('\n');
  }

  factory StaffRequest.fromSyncMap(Map<String, dynamic> map) {
    final salary = (map['salary'] as num?)?.toDouble() ??
        (map['amountValue'] as num?)?.toDouble() ??
        0;
    return StaffRequest(
      id: map['id']?.toString(),
      name: map['name']?.toString() ?? '',
      role: (map['role'] ?? map['jobTitle'] ?? '').toString(),
      salary: salary,
      salaryFrequency: (map['salaryFrequency'] ??
              map['salary_frequency'] ??
              map['paymentType'] ??
              'monthly')
          .toString(),
      phone: map['phone']?.toString(),
      notes: map['notes']?.toString(),
      propertyName: (map['propertyName'] ?? map['property_name'])?.toString(),
      propertyRef: (map['propertyRef'] ?? map['property_ref'])?.toString(),
      startDate: (map['startDate'] ?? map['start_date'])?.toString(),
      status: map['status']?.toString() ?? 'active',
      payDayLabel: map['payDayLabel']?.toString(),
      permissionRole: map['permissionRole']?.toString(),
      permissions: _stringList(map['permissions']),
      allProperties: map['allProperties'] is bool ? map['allProperties'] as bool : null,
      propertyRefs: _stringList(map['propertyRefs']),
    );
  }
}
