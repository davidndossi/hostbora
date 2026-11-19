import 'package:sqflite/sqflite.dart';

import '../../../core/utils/sync_freshness.dart';
import 'app_local_database.dart';

class IncomeRecord {
  const IncomeRecord({
    required this.id,
    required this.tenantName,
    required this.amountValue,
    required this.datePaidIso,
    required this.category,
    required this.notes,
    required this.apartment,
    required this.apartmentUnit,
    this.propertyRef = '',
    this.bookingId = '',
    required this.workspaceType,
    required this.currencyCode,
    required this.inputAmountValue,
    required this.createdAtMs,
    this.backendPaymentId = '',
    this.updatedAtMs = 0,
    this.tenantId = 0,
  });

  final int id;
  final String tenantName;
  final double amountValue;
  final String datePaidIso;
  final String category;
  final String notes;
  final String apartment;
  final String apartmentUnit;

  /// Hub id / [PropertyRecord.propertyRef] / `local_<id>` for listing-scoped totals.
  final String propertyRef;

  /// BnB booking key ([CheckInItem.bookingKey]) when payment is linked to a stay.
  final String bookingId;

  /// `rent` or `bnb` — matches [WorkspaceContextService] persistence.
  final String workspaceType;

  /// Currency the user entered; [amountValue] is always in base currency.
  final String currencyCode;
  final double inputAmountValue;
  final int createdAtMs;

  /// Remote backend UUID, populated after the record is synced online.
  final String backendPaymentId;

  /// Last local or applied remote edit. `0` means "use [createdAtMs]".
  final int updatedAtMs;

  /// Local [TenantRecord.id]. `0` means the payment is not linked to a tenant.
  final int tenantId;

  factory IncomeRecord.fromMap(Map<String, Object?> m) {
    return IncomeRecord(
      id: m['id']! as int,
      tenantName: m['tenant_name'] as String? ?? '',
      amountValue: (m['amount_value'] as num?)?.toDouble() ?? 0,
      datePaidIso: m['date_paid_iso'] as String? ?? '',
      category: m['category'] as String? ?? '',
      notes: m['notes'] as String? ?? '',
      apartment: m['apartment'] as String? ?? '',
      apartmentUnit: m['apartment_unit'] as String? ?? '',
      propertyRef: m['property_ref'] as String? ?? '',
      bookingId: m['booking_id'] as String? ?? '',
      workspaceType: m['workspace_type'] as String? ?? 'rent',
      currencyCode: m['currency_code'] as String? ?? 'TZS',
      inputAmountValue: (m['input_amount_value'] as num?)?.toDouble() ?? 0,
      createdAtMs: m['created_at_ms'] as int? ?? 0,
      backendPaymentId: m['backend_payment_id'] as String? ?? '',
      updatedAtMs: (m['updated_at_ms'] as num?)?.toInt() ?? 0,
      tenantId: (m['tenant_id'] as num?)?.toInt() ?? 0,
    );
  }

  /// Interprets [datePaidIso] as a local calendar day when it is `yyyy-MM-dd`,
  /// so month rollups are not shifted by UTC parsing of date-only strings.
  DateTime paidLocalCalendarOrCreated() {
    final raw = datePaidIso.trim();
    if (raw.length >= 10 && raw[4] == '-' && raw[7] == '-') {
      final y = int.tryParse(raw.substring(0, 4));
      final m = int.tryParse(raw.substring(5, 7));
      final d = int.tryParse(raw.substring(8, 10));
      if (y != null &&
          m != null &&
          d != null &&
          m >= 1 &&
          m <= 12 &&
          d >= 1 &&
          d <= 31) {
        return DateTime(y, m, d);
      }
    }
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    }
  }
}

/// Offline income rows stored in the shared [AppLocalDatabase.incomeTable].
class IncomeLocalDataSource {
  static const _table = AppLocalDatabase.incomeTable;

  Future<Database> get database => AppLocalDatabase.database;

  static String _normalizeWorkspace(String w) =>
      w.trim().toLowerCase() == 'bnb' ? 'bnb' : 'rent';

  static int _tenantIdFromNotes(String notes) {
    final match = _tenantIdNotePattern.firstMatch(notes);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static final _tenantIdNotePattern = RegExp(
    r'(?:^|[^\d])tenantId:(\d+)(?!\d)',
    multiLine: true,
  );

  static String _mergeRemoteNotes(String incoming, String? existing) {
    final remote = incoming.trim();
    final local = existing?.trim() ?? '';
    if (remote.isEmpty) return local;
    if (local.isEmpty) return remote;
    var merged = remote;
    for (final match in _tenantIdNotePattern.allMatches(local)) {
      final id = match.group(1);
      if (id == null || id.isEmpty) continue;
      final tag = 'tenantId:$id';
      if (_tenantIdNotePattern
          .allMatches(merged)
          .any((m) => m.group(1) == id)) {
        continue;
      }
      merged = '$merged\n$tag';
    }
    return merged;
  }

  Future<int> insert({
    required String tenantName,
    required double amountValue,
    required String datePaidIso,
    required String category,
    required String workspaceType,
    String notes = '',
    String apartment = '',
    String apartmentUnit = '',
    String propertyRef = '',
    String bookingId = '',
    String currencyCode = 'TZS',
    double inputAmountValue = 0,
    int tenantId = 0,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final linkedTenantId = tenantId > 0 ? tenantId : _tenantIdFromNotes(notes);
    return db.insert(_table, {
      'tenant_name': tenantName,
      'amount_value': amountValue,
      'currency_code': currencyCode.trim().isEmpty
          ? 'TZS'
          : currencyCode.trim().toUpperCase(),
      'input_amount_value': inputAmountValue <= 0
          ? amountValue
          : inputAmountValue,
      'date_paid_iso': datePaidIso,
      'category': category,
      'notes': notes,
      'apartment': apartment,
      'apartment_unit': apartmentUnit,
      'property_ref': propertyRef.trim(),
      'booking_id': bookingId.trim(),
      'workspace_type': _normalizeWorkspace(workspaceType),
      'tenant_id': linkedTenantId,
      'created_at_ms': now,
      'updated_at_ms': now,
    });
  }

  /// Income rows linked to a BnB booking ([CheckInItem.bookingKey]).
  Future<List<IncomeRecord>> getAllByBookingId(
    String bookingId, {
    String? workspaceType,
  }) async {
    final key = bookingId.trim();
    if (key.isEmpty) return const [];

    final db = await database;
    final where = StringBuffer('trim(booking_id) = ?');
    final args = <Object>[key];
    if (workspaceType != null) {
      where.write(
        " AND lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
      );
      args.add(_normalizeWorkspace(workspaceType));
    }
    final maps = await db.query(
      _table,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(IncomeRecord.fromMap).toList();
  }

  /// When [workspaceType] is null, returns rows for all workspaces (e.g. home
  /// overview filters BnB rows in Dart). Otherwise filters `income` by
  /// normalized `rent` / `bnb` (blank/null stored values count as `rent`).
  Future<void> backfillMissingTenantIds() async {
    final db = await database;
    final pending = await db.query(
      _table,
      columns: const [
        'id',
        'notes',
        'tenant_name',
        'property_ref',
        'apartment_unit',
      ],
      where: 'tenant_id = 0 OR tenant_id IS NULL',
    );
    if (pending.isEmpty) return;

    List<Map<String, Object?>> tenants;
    try {
      tenants = await db.query(
        AppLocalDatabase.tenantTable,
        columns: const [
          'id',
          'tenant_name',
          'property_ref',
          'unit_label',
          'apartment_unit_id',
        ],
      );
    } catch (_) {
      return;
    }
    if (tenants.isEmpty) return;

    for (final row in pending) {
      final fromNotes = _tenantIdFromNotes((row['notes'] as String?) ?? '');
      final tenantId = fromNotes > 0
          ? fromNotes
          : _tenantIdFromExistingRow(row, tenants);
      if (tenantId <= 0) continue;
      await db.update(
        _table,
        {'tenant_id': tenantId},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  static int _tenantIdFromExistingRow(
    Map<String, Object?> income,
    List<Map<String, Object?>> tenants,
  ) {
    final name = (income['tenant_name'] as String? ?? '').trim().toLowerCase();
    if (name.isEmpty) return 0;
    final ref = (income['property_ref'] as String? ?? '').trim();
    final unit = (income['apartment_unit'] as String? ?? '')
        .trim()
        .toLowerCase();
    final named = tenants.where((t) {
      return (t['tenant_name'] as String? ?? '').trim().toLowerCase() == name;
    }).toList();
    if (named.isEmpty) return 0;
    if (named.length == 1) {
      return (named.first['id'] as num?)?.toInt() ?? 0;
    }
    final sameRef = ref.isEmpty
        ? named
        : named
            .where((t) => (t['property_ref'] as String? ?? '').trim() == ref)
            .toList();
    final pool = sameRef.isNotEmpty ? sameRef : named;
    if (unit.isNotEmpty) {
      for (final t in pool) {
        final label = (t['unit_label'] as String? ?? '').trim().toLowerCase();
        final unitId =
            (t['apartment_unit_id'] as String? ?? '').trim().toLowerCase();
        if (label == unit || unitId == unit) {
          return (t['id'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return (pool.first['id'] as num?)?.toInt() ?? 0;
  }

  Future<List<IncomeRecord>> getAllNewestFirst({String? workspaceType}) async {
    await backfillMissingTenantIds();
    final db = await database;
    if (workspaceType == null) {
      final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
      return maps.map(IncomeRecord.fromMap).toList();
    }
    final w = _normalizeWorkspace(workspaceType);
    final maps = await db.query(
      _table,
      where:
          "lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
      whereArgs: [w],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(IncomeRecord.fromMap).toList();
  }

  /// Loads income rows whose property (joined by `property_ref`) is in BnB workspace.
  Future<List<IncomeRecord>> getAllForBnbWorkspaceByPropertyRefJoin() async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT i.*
      FROM ${AppLocalDatabase.incomeTable} i
      INNER JOIN ${AppLocalDatabase.propertiesTable} p
        ON p.property_ref = i.property_ref
      WHERE lower(trim(coalesce(nullif(trim(p.workspace_type), ''), 'rent'))) IN (?, ?)
      ORDER BY i.created_at_ms DESC
      ''',
      ['bnb', 'both'],
    );
    return maps.map(IncomeRecord.fromMap).toList();
  }

  /// Returns income rows for a specific [propertyRef] and [workspaceType].
  ///
  /// Workspace is normalized to `rent` / `bnb` and sorted newest first.
  Future<List<IncomeRecord>> getAllByPropertyRefAndWorkspace({
    required String propertyRef,
    required String workspaceType,
  }) async {
    final db = await database;
    final ref = propertyRef.trim();
    if (ref.isEmpty) return const [];

    final w = _normalizeWorkspace(workspaceType);
    final maps = await db.query(
      _table,
      where:
          "trim(property_ref) = ? AND lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
      whereArgs: [ref, w],
      orderBy: 'created_at_ms DESC',
    );
    return maps.map(IncomeRecord.fromMap).toList();
  }

  /// Ties an existing payment to a tenant so it is allocated to that tenant's
  /// rent months.
  ///
  /// Writes `tenant_id` and also the `tenantId:<id>` note: remote refreshes
  /// merge notes but not the local-only column, so the note keeps the link
  /// across syncs. Blank place fields are filled from the tenant; anything the
  /// payment already recorded is left alone. Not queued for sync because the
  /// remote payment has no tenant field.
  Future<void> linkToTenant({
    required int incomeId,
    required int tenantId,
    required String tenantName,
    String propertyRef = '',
    String apartment = '',
    String apartmentUnit = '',
  }) async {
    if (incomeId <= 0 || tenantId <= 0) return;
    final db = await database;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [incomeId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final row = rows.first;

    String blankOr(String column, String fallback) {
      final current = (row[column] as String? ?? '').trim();
      return current.isEmpty ? fallback.trim() : current;
    }

    final notes = (row['notes'] as String? ?? '').trim();
    final alreadyTagged = _tenantIdNotePattern
        .allMatches(notes)
        .any((m) => m.group(1) == '$tenantId');
    final tag = 'tenantId:$tenantId';
    final nextNotes = alreadyTagged
        ? notes
        : (notes.isEmpty ? tag : '$notes\n$tag');

    await db.update(
      _table,
      {
        'tenant_id': tenantId,
        'tenant_name': blankOr('tenant_name', tenantName),
        'property_ref': blankOr('property_ref', propertyRef),
        'apartment': blankOr('apartment', apartment),
        'apartment_unit': blankOr('apartment_unit', apartmentUnit),
        'notes': nextNotes,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [incomeId],
    );
  }

  Future<void> deleteById(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<IncomeRecord?> getById(int id) async {
    final db = await database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return IncomeRecord.fromMap(rows.first);
  }

  Future<void> saveBackendPaymentId({
    required int localId,
    required String backendId,
  }) async {
    if (backendId.isEmpty) return;
    final db = await database;
    await db.update(
      _table,
      {'backend_payment_id': backendId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Merges a server payment. The phone row is kept when it was edited later.
  Future<RemoteRowMerge<IncomeRecord>> upsertFromRemote({
    required String backendPaymentId,
    required String tenantName,
    required double amountValue,
    required String datePaidIso,
    required String category,
    required String notes,
    required String apartment,
    required String apartmentUnit,
    required String propertyRef,
    required String bookingId,
    required String workspaceType,
    required String currencyCode,
    required int remoteUpdatedAtMs,
    int tenantId = 0,
  }) async {
    final backendId = backendPaymentId.trim();
    final rows = await getAllNewestFirst();
    IncomeRecord? existing;
    if (backendId.isNotEmpty) {
      for (final row in rows) {
        if (row.backendPaymentId.trim() == backendId) {
          existing = row;
          break;
        }
      }
    }
    existing ??= _matchMoneyRow(
      rows,
      amountValue: amountValue,
      datePaidIso: datePaidIso,
      category: category,
      tenantName: tenantName,
      bookingId: bookingId,
    );
    if (existing != null &&
        SyncFreshness.phoneIsNewer(
          localUpdatedMs: existing.updatedAtMs,
          localCreatedMs: existing.createdAtMs,
          remoteUpdatedMs: remoteUpdatedAtMs,
        )) {
      if (backendId.isNotEmpty && existing.backendPaymentId.trim().isEmpty) {
        await saveBackendPaymentId(localId: existing.id, backendId: backendId);
        existing = await getById(existing.id) ?? existing;
      }
      return RemoteRowMerge(record: existing, keptLocal: true);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final appliedUpdated = remoteUpdatedAtMs > 0
        ? remoteUpdatedAtMs
        : (existing != null
            ? (existing.updatedAtMs > 0
                ? existing.updatedAtMs
                : existing.createdAtMs)
            : now);
    final db = await database;
    final data = <String, Object?>{
      'tenant_name': tenantName.trim().isNotEmpty
          ? tenantName.trim()
          : (existing?.tenantName ?? ''),
      'amount_value': amountValue > 0 ? amountValue : (existing?.amountValue ?? 0),
      'currency_code': currencyCode.trim().isNotEmpty
          ? currencyCode.trim().toUpperCase()
          : (existing?.currencyCode ?? 'TZS'),
      'input_amount_value': amountValue > 0
          ? amountValue
          : (existing?.inputAmountValue ?? 0),
      'date_paid_iso': datePaidIso.trim().isNotEmpty
          ? datePaidIso.trim()
          : (existing?.datePaidIso ?? ''),
      'category': category.trim().isNotEmpty
          ? category.trim()
          : (existing?.category ?? ''),
      'notes': _mergeRemoteNotes(notes, existing?.notes),
      'apartment': apartment.trim().isNotEmpty
          ? apartment.trim()
          : (existing?.apartment ?? ''),
      'apartment_unit': apartmentUnit.trim().isNotEmpty
          ? apartmentUnit.trim()
          : (existing?.apartmentUnit ?? ''),
      'property_ref': propertyRef.trim().isNotEmpty
          ? propertyRef.trim()
          : (existing?.propertyRef ?? ''),
      'booking_id': bookingId.trim().isNotEmpty
          ? bookingId.trim()
          : (existing?.bookingId ?? ''),
      'workspace_type': workspaceType.trim().isNotEmpty
          ? _normalizeWorkspace(workspaceType)
          : (existing?.workspaceType ?? 'rent'),
      'backend_payment_id': backendId.isNotEmpty
          ? backendId
          : (existing?.backendPaymentId ?? ''),
      'tenant_id': tenantId > 0
          ? tenantId
          : (existing?.tenantId ?? _tenantIdFromNotes(notes)),
      'created_at_ms': existing?.createdAtMs ?? now,
      'updated_at_ms': appliedUpdated,
    };
    if (existing != null) {
      await db.update(_table, data, where: 'id = ?', whereArgs: [existing.id]);
      final saved = await getById(existing.id);
      return RemoteRowMerge(record: saved ?? existing, keptLocal: false);
    }
    final id = await db.insert(_table, data);
    final saved = await getById(id);
    return RemoteRowMerge(
      record: saved!,
      keptLocal: false,
    );
  }

  IncomeRecord? _matchMoneyRow(
    List<IncomeRecord> rows, {
    required double amountValue,
    required String datePaidIso,
    required String category,
    required String tenantName,
    required String bookingId,
  }) {
    final day = _dayKey(datePaidIso);
    final name = tenantName.trim().toLowerCase();
    final cat = category.trim().toLowerCase();
    final booking = bookingId.trim();
    for (final row in rows) {
      if (row.backendPaymentId.trim().isNotEmpty) continue;
      if ((row.amountValue - amountValue).abs() > 0.01) continue;
      if (day.isNotEmpty && _dayKey(row.datePaidIso) != day) continue;
      if (booking.isNotEmpty && row.bookingId.trim() == booking) return row;
      if (name.isNotEmpty &&
          row.tenantName.trim().toLowerCase() == name &&
          (cat.isEmpty || row.category.trim().toLowerCase() == cat)) {
        return row;
      }
    }
    return null;
  }

  static String _dayKey(String raw) {
    final text = raw.trim();
    if (text.length >= 10) return text.substring(0, 10);
    return text;
  }
}
