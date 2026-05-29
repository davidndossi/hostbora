import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '/app/core/utils/property_listing_image_assigner.dart';

/// Central SQLite database for offline storage.
///
/// [dbVersion] is **1** for fresh local test cycles.
/// Full schema (including `workspace_type` and `income.property_ref`) is
/// created in [_createSchema], while [onOpen] keeps legacy repair guards.
///
/// The DB file was renamed to [dbName] so installs that still had the old
/// `paa_yangu_local.db` (user_version 24) do not hit a downgrade error; that
/// file is simply left unused until the OS removes it.
///
/// To wipe everything: uninstall the app, or call [deleteLocalDatabaseFile]
/// and **fully restart** the process before touching any repository again.
///
/// Keep table names/constants here so all local data sources use the same DB.
class AppLocalDatabase {
  AppLocalDatabase._();

  static const dbName = 'paa_yangu_local_v1.db';
  static const dbVersion = 1;

  static const propertiesTable = 'properties';
  static const propertyUnitsTable = 'property_units';
  static const staffTable = 'staff';
  static const incomeTable = 'income';
  static const expenseTable = 'expense';
  static const tenantTable = 'tenant';
  static const scheduledMaintenanceTable = 'scheduled_maintenance';
  static const rentStaffTable = 'rent_staff';
  static const rentLoyaltyOfferTable = 'rent_loyalty_offer';
  static const rentTenantChargeTable = 'rent_tenant_charge';
  static const rentPaymentReminderTable = 'rent_payment_reminder';
  static const rentNotificationLogTable = 'rent_notification_log';
  static const rentPropertyEstimateTable = 'rent_property_estimate';
  static const rentUtilityTopupTable = 'rent_utility_topup';
  static const rentWhatsappTemplateTable = 'rent_whatsapp_template';
  static const propertyMembersTable = 'property_members';
  static const offlineSyncQueueTable = 'offline_sync_queue';
  static const exchangeRatesTable = 'exchange_rates';
  static const scheduledWhatsappTable = 'scheduled_whatsapp';

  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, dbName);
    _db = await openDatabase(
      path,
      version: dbVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _migrate(db, oldVersion, newVersion);
      },
      onOpen: (db) async {
        // Repairs schemas where user_version advanced but ALTER steps did not
        // all run (e.g. income/expense missing workspace_type while properties had it).
        await _ensureWorkspaceTypeColumns(db);
        await _ensureIncomePropertyRefColumn(db);
        await _ensureUtilityTopupPropertyRefColumn(db);
        await _ensurePropertiesFloorCountColumn(db);
        await _ensurePropertiesCoverPhotoPathColumn(db);
        await _ensureIncomeBookingIdColumn(db);
        await _ensureCurrencyColumns(db);
        await _ensureExchangeRatesTable(db);
        await _ensureScheduledWhatsappTable(db);
      },
    );
    return _db!;
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $propertiesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        location TEXT NOT NULL,
        name TEXT NOT NULL DEFAULT '',
        type TEXT NOT NULL DEFAULT '',
        tenants INTEGER NOT NULL DEFAULT 0,
        units INTEGER NOT NULL DEFAULT 0,
        property_ref TEXT NOT NULL DEFAULT '',
        owner_user_id TEXT NOT NULL DEFAULT '',
        workspace_type TEXT NOT NULL DEFAULT 'rent',
        created_at_ms INTEGER NOT NULL,
        rent_amount TEXT NOT NULL DEFAULT '',
        rent_frequency TEXT NOT NULL DEFAULT '',
        min_rental_duration TEXT NOT NULL DEFAULT '',
        units_json TEXT NOT NULL DEFAULT '',
        floor_count INTEGER NOT NULL DEFAULT 1,
        cover_photo_path TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_${propertiesTable}_id_workspace ON $propertiesTable(id, workspace_type)',
    );
    await db.execute('''
      CREATE TABLE $propertyUnitsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_unit_ref TEXT NOT NULL DEFAULT '',
        property_ref TEXT NOT NULL DEFAULT '',
        unit_name TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT '',
        rent_amount REAL NOT NULL DEFAULT 0,
        rent_frequency TEXT NOT NULL DEFAULT '',
        min_rent_duration TEXT NOT NULL DEFAULT '',
        max_guests INTEGER NOT NULL DEFAULT 0,
        rooms INTEGER NOT NULL DEFAULT 0,
        floor INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_${propertyUnitsTable}_property_ref ON $propertyUnitsTable(property_ref)',
    );
    await db.execute('''
      CREATE TABLE $staffTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        property_ref TEXT NOT NULL DEFAULT '',
        job_title TEXT NOT NULL DEFAULT '',
        pay_amount_label TEXT NOT NULL DEFAULT '',
        pay_day_label TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL,
        payment_type TEXT NOT NULL DEFAULT 'monthly',
        amount_value REAL NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE $incomeTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_name TEXT NOT NULL,
        amount_value REAL NOT NULL,
        date_paid_iso TEXT NOT NULL,
        category TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        apartment TEXT NOT NULL DEFAULT '',
        apartment_unit TEXT NOT NULL DEFAULT '',
        property_ref TEXT NOT NULL DEFAULT '',
        booking_id TEXT NOT NULL DEFAULT '',
        workspace_type TEXT NOT NULL DEFAULT 'rent',
        currency_code TEXT NOT NULL DEFAULT 'TZS',
        input_amount_value REAL NOT NULL DEFAULT 0,
        created_at_ms INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${incomeTable}_booking_id ON $incomeTable(booking_id) WHERE booking_id != ""',
    );
    await db.execute('''
      CREATE TABLE $expenseTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_name TEXT NOT NULL DEFAULT '',
        amount_value REAL NOT NULL,
        date_paid_iso TEXT NOT NULL,
        category TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        apartment TEXT NOT NULL DEFAULT '',
        apartment_unit TEXT NOT NULL DEFAULT '',
        workspace_type TEXT NOT NULL DEFAULT 'rent',
        currency_code TEXT NOT NULL DEFAULT 'TZS',
        input_amount_value REAL NOT NULL DEFAULT 0,
        created_at_ms INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $exchangeRatesTable (
        currency TEXT PRIMARY KEY,
        buying REAL NOT NULL,
        selling REAL NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $tenantTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_label TEXT NOT NULL,
        property_ref TEXT NOT NULL DEFAULT '',
        apartment_unit_id TEXT NOT NULL DEFAULT '',
        unit_label TEXT NOT NULL DEFAULT '',
        tenant_name TEXT NOT NULL,
        gender TEXT NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        rent_frequency TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        email TEXT NOT NULL DEFAULT '',
        is_whatsapp INTEGER NOT NULL DEFAULT 0,
        lease_start_iso TEXT NOT NULL,
        lease_end_iso TEXT NOT NULL,
        payment_status TEXT NOT NULL DEFAULT 'pending',
        contract_file_path TEXT NOT NULL DEFAULT '',
        contract_file_name TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_${tenantTable}_listing_dates ON $tenantTable(property_ref, lease_start_iso, lease_end_iso)',
    );
    await db.execute('''
      CREATE TABLE $scheduledMaintenanceTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_label TEXT NOT NULL,
        property_ref TEXT NOT NULL DEFAULT '',
        apartment_unit_id TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        scheduled_date_iso TEXT NOT NULL,
        priority TEXT NOT NULL,
        notification_id INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $rentStaffTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        job_title TEXT NOT NULL DEFAULT '',
        pay_amount_label TEXT NOT NULL DEFAULT '',
        pay_day_label TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL,
        payment_type TEXT NOT NULL DEFAULT 'monthly',
        amount_value REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $rentLoyaltyOfferTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        min_stay_months INTEGER NOT NULL,
        revenue_threshold_tsh REAL NOT NULL,
        offer_type TEXT NOT NULL,
        terms TEXT NOT NULL,
        created_at_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $rentTenantChargeTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_label TEXT NOT NULL,
        charge_type TEXT NOT NULL,
        amount_tsh REAL NOT NULL,
        description TEXT NOT NULL,
        created_at_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $rentPaymentReminderTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_name TEXT NOT NULL,
        property_label TEXT NOT NULL,
        balance_tsh INTEGER NOT NULL,
        reminder_at_iso TEXT NOT NULL,
        push_enabled INTEGER NOT NULL DEFAULT 1,
        whatsapp_enabled INTEGER NOT NULL DEFAULT 1,
        email_enabled INTEGER NOT NULL DEFAULT 0,
        notification_id INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $scheduledWhatsappTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workspace TEXT NOT NULL DEFAULT 'rent',
        recipient_phone TEXT NOT NULL,
        recipient_label TEXT NOT NULL DEFAULT '',
        message_body TEXT NOT NULL DEFAULT '',
        template_name TEXT NOT NULL DEFAULT '',
        language_code TEXT NOT NULL DEFAULT '',
        body_parameters_json TEXT NOT NULL DEFAULT '[]',
        header_parameters_json TEXT NOT NULL DEFAULT '[]',
        scheduled_at_iso TEXT NOT NULL,
        notification_id INTEGER NOT NULL DEFAULT 0,
        sent INTEGER NOT NULL DEFAULT 0,
        created_at_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $rentNotificationLogTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        action_label TEXT NOT NULL DEFAULT '',
        payload TEXT NOT NULL DEFAULT '',
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $rentPropertyEstimateTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_ref TEXT NOT NULL UNIQUE,
        property_label TEXT NOT NULL,
        purchase_cost REAL NOT NULL DEFAULT 0,
        renovation_cost REAL NOT NULL DEFAULT 0,
        expected_monthly_income REAL NOT NULL DEFAULT 0,
        expected_monthly_expense REAL NOT NULL DEFAULT 0,
        target_occupancy_percent REAL NOT NULL DEFAULT 0,
        created_at_ms INTEGER NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $rentUtilityTopupTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        units_added REAL NOT NULL,
        amount_tsh REAL NOT NULL DEFAULT 0,
        provider TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        property_label TEXT NOT NULL DEFAULT '',
        property_ref TEXT NOT NULL DEFAULT '',
        date_iso TEXT NOT NULL,
        created_at_ms INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_${rentUtilityTopupTable}_kind_date ON $rentUtilityTopupTable(kind, date_iso)',
    );

    await db.execute('''
      CREATE TABLE $rentWhatsappTemplateTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'utility',
        language TEXT NOT NULL DEFAULT 'en_US',
        header_type TEXT NOT NULL DEFAULT 'none',
        header_text TEXT NOT NULL DEFAULT '',
        body_text TEXT NOT NULL,
        footer_text TEXT NOT NULL DEFAULT '',
        buttons_json TEXT NOT NULL DEFAULT '',
        sample_variables_json TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'draft',
        submitted_at_ms INTEGER NOT NULL DEFAULT 0,
        approved_at_ms INTEGER NOT NULL DEFAULT 0,
        rejection_reason TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_${rentWhatsappTemplateTable}_name ON $rentWhatsappTemplateTable(name, language)',
    );

    await db.execute('''
      CREATE TABLE $propertyMembersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_ref TEXT NOT NULL,
        user_id TEXT NOT NULL,
        workspace_type TEXT NOT NULL DEFAULT 'rent',
        role TEXT NOT NULL DEFAULT 'co_host',
        created_at_ms INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX idx_${propertyMembersTable}_unique ON $propertyMembersTable(property_ref, user_id, workspace_type)',
    );
    await db.execute(
      'CREATE INDEX idx_${propertyMembersTable}_workspace_user ON $propertyMembersTable(workspace_type, user_id)',
    );

    await db.execute('''
      CREATE TABLE $offlineSyncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        dedupe_key TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending',
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_${offlineSyncQueueTable}_status_created ON $offlineSyncQueueTable(status, created_at_ms)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_${offlineSyncQueueTable}_dedupe ON $offlineSyncQueueTable(dedupe_key) WHERE dedupe_key != ""',
    );
  }

  static Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _ensureWorkspaceTypeColumns(db);
    }
    if (oldVersion < 4) {
      await _ensureIncomePropertyRefColumn(db);
    }
    if (oldVersion < 5) {
      await _ensureIncomeBookingIdColumn(db);
    }
  }

  static Future<void> _ensureCurrencyColumns(Database db) async {
    await _addColumnIfMissing(
      db,
      incomeTable,
      'currency_code',
      "TEXT NOT NULL DEFAULT 'TZS'",
    );
    await _addColumnIfMissing(
      db,
      incomeTable,
      'input_amount_value',
      'REAL NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      db,
      expenseTable,
      'currency_code',
      "TEXT NOT NULL DEFAULT 'TZS'",
    );
    await _addColumnIfMissing(
      db,
      expenseTable,
      'input_amount_value',
      'REAL NOT NULL DEFAULT 0',
    );
  }

  static Future<void> _ensureExchangeRatesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $exchangeRatesTable (
        currency TEXT PRIMARY KEY,
        buying REAL NOT NULL,
        selling REAL NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _ensureIncomeBookingIdColumn(Database db) async {
    await _addColumnIfMissing(
      db,
      incomeTable,
      'booking_id',
      "TEXT NOT NULL DEFAULT ''",
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${incomeTable}_booking_id ON $incomeTable(booking_id) WHERE booking_id != ""',
    );
  }

  static Future<void> _ensureIncomePropertyRefColumn(Database db) async {
    await _addColumnIfMissing(
      db,
      incomeTable,
      'property_ref',
      "TEXT NOT NULL DEFAULT ''",
    );
  }

  static Future<void> _ensureUtilityTopupPropertyRefColumn(Database db) async {
    await _addColumnIfMissing(
      db,
      rentUtilityTopupTable,
      'property_ref',
      "TEXT NOT NULL DEFAULT ''",
    );
  }

  static Future<void> _ensurePropertiesFloorCountColumn(Database db) async {
    await _addColumnIfMissing(
      db,
      propertiesTable,
      'floor_count',
      'INTEGER NOT NULL DEFAULT 1',
    );
  }

  static Future<void> _ensurePropertiesCoverPhotoPathColumn(Database db) async {
    await _addColumnIfMissing(
      db,
      propertiesTable,
      'cover_photo_path',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _backfillPropertyCoverPhotoPaths(db);
  }

  /// Assigns LR-1..LR-14 images to legacy rows missing a cover path.
  static Future<void> _backfillPropertyCoverPhotoPaths(Database db) async {
    if (!await _tableExists(db, propertiesTable)) return;
    if (!await _columnExists(db, propertiesTable, 'cover_photo_path')) return;

    final rows = await db.query(
      propertiesTable,
      columns: ['id', 'property_ref', 'name', 'cover_photo_path'],
    );
    for (final row in rows) {
      final existing = (row['cover_photo_path'] as String?)?.trim() ?? '';
      if (existing.isNotEmpty) continue;
      final id = row['id'] as int?;
      if (id == null) continue;
      final ref = row['property_ref'] as String? ?? '';
      final name = row['name'] as String? ?? '';
      final path = PropertyListingImageAssigner.assignForProperty(
        propertyRef: ref,
        localPropertyId: id,
        propertyName: name,
      );
      await db.update(
        propertiesTable,
        {'cover_photo_path': path},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Idempotent: adds [workspace_type] on legacy tables and fixes indexes.
  static Future<void> _ensureWorkspaceTypeColumns(Database db) async {
    const colDef = "TEXT NOT NULL DEFAULT 'rent'";
    await _addColumnIfMissing(db, propertiesTable, 'workspace_type', colDef);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${propertiesTable}_id_workspace ON $propertiesTable(id, workspace_type)',
    );

    await _addColumnIfMissing(db, incomeTable, 'workspace_type', colDef);
    await _addColumnIfMissing(db, expenseTable, 'workspace_type', colDef);

    final hadPmWorkspace =
        await _columnExists(db, propertyMembersTable, 'workspace_type');
    await _addColumnIfMissing(db, propertyMembersTable, 'workspace_type', colDef);
    if (!hadPmWorkspace &&
        await _columnExists(db, propertyMembersTable, 'workspace_type')) {
      await db.execute('DROP INDEX IF EXISTS idx_${propertyMembersTable}_unique');
      await db.execute('DROP INDEX IF EXISTS idx_${propertyMembersTable}_workspace_user');
      await db.execute(
        'CREATE UNIQUE INDEX idx_${propertyMembersTable}_unique ON $propertyMembersTable(property_ref, user_id, workspace_type)',
      );
      await db.execute(
        'CREATE INDEX idx_${propertyMembersTable}_workspace_user ON $propertyMembersTable(workspace_type, user_id)',
      );
    }
  }

  static Future<void> _ensureScheduledWhatsappTable(Database db) async {
    if (await _tableExists(db, scheduledWhatsappTable)) return;
    await db.execute('''
      CREATE TABLE $scheduledWhatsappTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workspace TEXT NOT NULL DEFAULT 'rent',
        recipient_phone TEXT NOT NULL,
        recipient_label TEXT NOT NULL DEFAULT '',
        message_body TEXT NOT NULL DEFAULT '',
        template_name TEXT NOT NULL DEFAULT '',
        language_code TEXT NOT NULL DEFAULT '',
        body_parameters_json TEXT NOT NULL DEFAULT '[]',
        header_parameters_json TEXT NOT NULL DEFAULT '[]',
        scheduled_at_iso TEXT NOT NULL,
        notification_id INTEGER NOT NULL DEFAULT 0,
        sent INTEGER NOT NULL DEFAULT 0,
        created_at_ms INTEGER NOT NULL
      )
    ''');
  }

  static Future<bool> _tableExists(Database db, String table) async {
    final rows = await db.rawQuery(
      'SELECT 1 FROM sqlite_master WHERE type = ? AND name = ? LIMIT 1',
      ['table', table],
    );
    return rows.isNotEmpty;
  }

  static Future<bool> _columnExists(Database db, String table, String column) async {
    if (!await _tableExists(db, table)) return false;
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.any((r) => r['name'] == column);
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String sqlTypeAndConstraints,
  ) async {
    if (!await _tableExists(db, table)) return;
    if (await _columnExists(db, table, column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $sqlTypeAndConstraints');
  }

  /// Closes the singleton handle (if any) and deletes the DB file from disk.
  ///
  /// After this, **restart the app** (or hot restart) before using local DB
  /// again — in-memory [Database] caches inside data sources are not cleared.
  static Future<void> deleteLocalDatabaseFile() async {
    try {
      await _db?.close();
    } catch (_) {}
    _db = null;
    final dir = await getApplicationDocumentsDirectory();
    await deleteDatabase(p.join(dir.path, dbName));
  }

  static const List<String> _allDataTables = [
    offlineSyncQueueTable,
    propertyMembersTable,
    rentWhatsappTemplateTable,
    rentUtilityTopupTable,
    rentPropertyEstimateTable,
    rentNotificationLogTable,
    rentPaymentReminderTable,
    scheduledWhatsappTable,
    rentTenantChargeTable,
    rentLoyaltyOfferTable,
    rentStaffTable,
    scheduledMaintenanceTable,
    tenantTable,
    expenseTable,
    incomeTable,
    staffTable,
    propertyUnitsTable,
    propertiesTable,
  ];

  /// Deletes every row from all local tables (schema and DB user version unchanged).
  static Future<void> deleteAllRows() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final name in _allDataTables) {
        await txn.delete(name);
      }
    });
  }

  /// Clears only Rent workspace tables and keeps BnB data untouched.
  static Future<void> clearRentTables() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(propertiesTable);
      await txn.delete(rentStaffTable);
      await txn.delete(
        incomeTable,
        where:
            "lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
        whereArgs: ['rent'],
      );
      await txn.delete(
        expenseTable,
        where:
            "lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
        whereArgs: ['rent'],
      );
      await txn.delete(tenantTable);
      await txn.delete(rentLoyaltyOfferTable);
      await txn.delete(rentTenantChargeTable);
      await txn.delete(scheduledMaintenanceTable);
      await txn.delete(rentPaymentReminderTable);
      await txn.delete(rentNotificationLogTable);
      await txn.delete(rentPropertyEstimateTable);
      await txn.delete(rentUtilityTopupTable);
      await txn.delete(rentWhatsappTemplateTable);
      await txn.delete(propertyMembersTable, where: 'workspace_type = ?', whereArgs: ['rent']);
      await txn.delete(offlineSyncQueueTable);
    });
  }

  /// Clears only BnB workspace tables and keeps Rent data untouched.
  static Future<void> clearBnBTables() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(propertiesTable);
      await txn.delete(tenantTable);
      await txn.delete(
        incomeTable,
        where:
            "lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
        whereArgs: ['bnb'],
      );
      await txn.delete(
        expenseTable,
        where:
            "lower(trim(coalesce(nullif(trim(workspace_type), ''), 'rent'))) = ?",
        whereArgs: ['bnb'],
      );
      await txn.delete(propertyMembersTable, where: 'workspace_type = ?', whereArgs: ['bnb']);
    });
  }
}
