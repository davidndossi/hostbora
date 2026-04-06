import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Central SQLite database for offline storage.
///
/// Keep table names/constants here so all local data sources use the same DB.
class AppLocalDatabase {
  AppLocalDatabase._();

  static const dbName = 'paa_yangu_local.db';
  static const dbVersion = 10;

  static const rentPropertiesTable = 'rent_properties';
  static const rentStaffTable = 'rent_staff';
  static const rentIncomeTable = 'rent_income';
  static const rentExpenseTable = 'rent_expense';
  static const rentTenantTable = 'rent_tenant';
  static const rentLoyaltyOfferTable = 'rent_loyalty_offer';
  static const rentTenantChargeTable = 'rent_tenant_charge';
  static const rentScheduledMaintenanceTable = 'rent_scheduled_maintenance';
  static const rentPaymentReminderTable = 'rent_payment_reminder';
  static const rentNotificationLogTable = 'rent_notification_log';
  static const offlineSyncQueueTable = 'offline_sync_queue';

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
    );
    return _db!;
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $rentPropertiesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_location TEXT NOT NULL,
        apartment_suite TEXT NOT NULL DEFAULT '',
        property_type TEXT NOT NULL DEFAULT '',
        rent_amount TEXT NOT NULL DEFAULT '',
        rent_frequency TEXT NOT NULL DEFAULT '',
        min_rental_duration TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL,
        units_json TEXT NOT NULL DEFAULT ''
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
      CREATE TABLE $rentIncomeTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_name TEXT NOT NULL,
        amount_value REAL NOT NULL,
        date_paid_iso TEXT NOT NULL,
        category TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $rentExpenseTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tenant_name TEXT NOT NULL DEFAULT '',
        amount_value REAL NOT NULL,
        date_paid_iso TEXT NOT NULL,
        category TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $rentTenantTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_label TEXT NOT NULL,
        tenant_name TEXT NOT NULL,
        gender TEXT NOT NULL,
        rent_amount_value REAL NOT NULL,
        rent_frequency TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        email TEXT NOT NULL DEFAULT '',
        is_whatsapp INTEGER NOT NULL DEFAULT 0,
        lease_start_iso TEXT NOT NULL,
        lease_end_iso TEXT NOT NULL,
        contract_file_path TEXT NOT NULL DEFAULT '',
        contract_file_name TEXT NOT NULL DEFAULT '',
        created_at_ms INTEGER NOT NULL
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
      CREATE TABLE $rentScheduledMaintenanceTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_label TEXT NOT NULL,
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
    // v1 -> v2 had additional columns in feature-local databases.
    if (oldVersion < 2) {
      await _safeAlter(
        db,
        'ALTER TABLE $rentPropertiesTable ADD COLUMN units_json TEXT NOT NULL DEFAULT ""',
      );
      await _safeAlter(
        db,
        "ALTER TABLE $rentStaffTable ADD COLUMN payment_type TEXT NOT NULL DEFAULT 'monthly'",
      );
      await _safeAlter(
        db,
        'ALTER TABLE $rentStaffTable ADD COLUMN amount_value REAL NOT NULL DEFAULT 0',
      );
    }

    // v3 introduces shared DB file; keep room for future migrations.
    if (oldVersion < 3 && newVersion >= 3) {
      // no-op: schema already includes current columns.
    }

    // v4 introduces generic offline sync queue table.
    if (oldVersion < 4 && newVersion >= 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $offlineSyncQueueTable (
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
        'CREATE INDEX IF NOT EXISTS idx_${offlineSyncQueueTable}_status_created ON $offlineSyncQueueTable(status, created_at_ms)',
      );
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_${offlineSyncQueueTable}_dedupe ON $offlineSyncQueueTable(dedupe_key) WHERE dedupe_key != ""',
      );
    }

    // v5 introduces rent income offline storage table.
    if (oldVersion < 5 && newVersion >= 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $rentIncomeTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tenant_name TEXT NOT NULL,
          amount_value REAL NOT NULL,
          date_paid_iso TEXT NOT NULL,
          category TEXT NOT NULL,
          notes TEXT NOT NULL DEFAULT '',
          created_at_ms INTEGER NOT NULL
        )
      ''');
    }

    // v6 introduces expense + tenant offline storage tables.
    if (oldVersion < 6 && newVersion >= 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $rentExpenseTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tenant_name TEXT NOT NULL DEFAULT '',
          amount_value REAL NOT NULL,
          date_paid_iso TEXT NOT NULL,
          category TEXT NOT NULL,
          notes TEXT NOT NULL DEFAULT '',
          created_at_ms INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $rentTenantTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          property_label TEXT NOT NULL,
          tenant_name TEXT NOT NULL,
          gender TEXT NOT NULL,
          rent_amount_value REAL NOT NULL,
          rent_frequency TEXT NOT NULL,
          phone_number TEXT NOT NULL,
          email TEXT NOT NULL DEFAULT '',
          is_whatsapp INTEGER NOT NULL DEFAULT 0,
          lease_start_iso TEXT NOT NULL,
          lease_end_iso TEXT NOT NULL,
          created_at_ms INTEGER NOT NULL
        )
      ''');
    }

    // v7 introduces loyalty offers + tenant charges offline storage tables.
    if (oldVersion < 7 && newVersion >= 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $rentLoyaltyOfferTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          min_stay_months INTEGER NOT NULL,
          revenue_threshold_tsh REAL NOT NULL,
          offer_type TEXT NOT NULL,
          terms TEXT NOT NULL,
          created_at_ms INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $rentTenantChargeTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          property_label TEXT NOT NULL,
          charge_type TEXT NOT NULL,
          amount_tsh REAL NOT NULL,
          description TEXT NOT NULL,
          created_at_ms INTEGER NOT NULL
        )
      ''');
    }

    // v8 introduces offline scheduled maintenance + payment reminder tables.
    if (oldVersion < 8 && newVersion >= 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $rentScheduledMaintenanceTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          property_label TEXT NOT NULL,
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
        CREATE TABLE IF NOT EXISTS $rentPaymentReminderTable (
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
    }

    // v9 introduces tenant contract file columns.
    if (oldVersion < 9 && newVersion >= 9) {
      await _safeAlter(
        db,
        'ALTER TABLE $rentTenantTable ADD COLUMN contract_file_path TEXT NOT NULL DEFAULT ""',
      );
      await _safeAlter(
        db,
        'ALTER TABLE $rentTenantTable ADD COLUMN contract_file_name TEXT NOT NULL DEFAULT ""',
      );
    }

    // v10 introduces concierge inbox notification log table.
    if (oldVersion < 10 && newVersion >= 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $rentNotificationLogTable (
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
    }
  }

  static Future<void> _safeAlter(Database db, String sql) async {
    try {
      await db.execute(sql);
    } catch (_) {
      // Ignore "duplicate column" and missing table errors during mixed migrations.
    }
  }
}
