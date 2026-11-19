import 'package:get_storage/get_storage.dart';
import 'package:sqflite/sqflite.dart';

import '../db/app_local_database.dart';
import '../db/property_local_data_source.dart';
import '../preference/preference_manager.dart';

/// Drops on-device account data so a new sign-in cannot see the previous
/// account's tenants, inventory, properties, documents, or pending sync queue.
class LocalAccountDataReset {
  LocalAccountDataReset._();

  static Future<void>? _inFlight;

  static Future<void> wipe() async {
    // Delete the file, do not DELETE FROM. Row deletes left the same
    // inode open: data sources cached the handle, and on iOS a deleted
    // file that still has a descriptor keeps its contents. The next
    // [AppLocalDatabase.database] call recreates an empty schema.
    await AppLocalDatabase.deleteLocalDatabaseFile();
    try {
      await GetStorage().erase();
    } catch (_) {}
    PropertyLocalDataSource.notifyChanged();
  }

  /// Keeps local data only when it belongs to [userId]. A different account
  /// replaces that data before any screen or sync can read it.
  static Future<void> alignToUser(PreferenceManager prefs, {String? userId}) {
    final running = _inFlight;
    if (running != null) return running;
    final run = _align(prefs, userId: userId);
    _inFlight = run;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) _inFlight = null;
    });
  }

  static Future<void> _align(PreferenceManager prefs, {String? userId}) async {
    var next = userId?.trim() ?? '';
    if (next.isEmpty) {
      next = await _storedUserId(prefs);
    }
    if (next.isEmpty) return;

    final owner = (await prefs.getString(
      PreferenceManager.keyLocalDataOwnerUserId,
      defaultValue: '',
    )).trim();
    if (owner.isNotEmpty && owner != next) {
      await wipe();
      await prefs.setString(PreferenceManager.keyLocalDataOwnerUserId, next);
      return;
    }

    final db = await AppLocalDatabase.database;
    final storedUser = await _storedUserId(prefs);
    final owned = await _count(
      db,
      AppLocalDatabase.propertiesTable,
      'owner_user_id = ?',
      [next],
    );
    final foreign = await _count(
      db,
      AppLocalDatabase.propertiesTable,
      "trim(owner_user_id) != '' AND owner_user_id != ?",
      [next],
    );
    final unscoped = await _count(
      db,
      AppLocalDatabase.propertiesTable,
      "trim(owner_user_id) = ''",
      const [],
    );
    final tenants = await _count(
      db,
      AppLocalDatabase.tenantTable,
      null,
      const [],
    );
    final samePerson = storedUser == next && foreign == 0;

    // Another account's rows, or tenants left behind with no property of this
    // user, do not belong to the new sign-in.
    if (owned == 0 && (foreign > 0 || tenants > 0) && !samePerson) {
      await wipe();
      await prefs.setString(PreferenceManager.keyLocalDataOwnerUserId, next);
      return;
    }

    if (owner.isEmpty && samePerson && unscoped > 0) {
      await db.update(AppLocalDatabase.propertiesTable, {
        'owner_user_id': next,
      }, where: "trim(owner_user_id) = ''");
    } else if (foreign > 0 || (!samePerson && unscoped > 0)) {
      await _deleteOtherAccounts(db, next);
    }

    await prefs.setString(PreferenceManager.keyLocalDataOwnerUserId, next);
  }

  static Future<String> _storedUserId(PreferenceManager prefs) async {
    try {
      return (await prefs.getUser()).id?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<int> _count(
    Database db,
    String table,
    String? where,
    List<Object?> args,
  ) async {
    final existing = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    );
    if (existing.isEmpty) return 0;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $table${where == null ? '' : ' WHERE $where'}',
      args,
    );
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  /// Removes properties, tenants, and inventory that are not [userId]'s.
  static Future<void> _deleteOtherAccounts(Database db, String userId) async {
    final props = AppLocalDatabase.propertiesTable;
    final ownedRows = await db.query(
      props,
      columns: ['id', 'property_ref'],
      where: 'owner_user_id = ?',
      whereArgs: [userId],
    );
    final refs = <String>{};
    for (final row in ownedRows) {
      final ref = (row['property_ref'] ?? '').toString().trim();
      if (ref.isNotEmpty) refs.add(ref);
      final id = row['id'];
      if (id != null) {
        refs.add('local_$id');
        refs.add('legacy_$id');
      }
    }

    await db.delete(
      props,
      where: "trim(owner_user_id) != '' AND owner_user_id != ?",
      whereArgs: [userId],
    );

    Future<void> deleteUnlessOwned(String table, String column) async {
      final existing = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        [table],
      );
      if (existing.isEmpty) return;
      if (refs.isEmpty) {
        await db.delete(table);
        return;
      }
      final placeholders = List.filled(refs.length, '?').join(',');
      await db.delete(
        table,
        where: '$column NOT IN ($placeholders)',
        whereArgs: refs.toList(),
      );
    }

    await deleteUnlessOwned(AppLocalDatabase.tenantTable, 'property_ref');
    await deleteUnlessOwned(
      AppLocalDatabase.inventoryItemTable,
      'property_ref',
    );
    await deleteUnlessOwned(AppLocalDatabase.incomeTable, 'property_ref');
    await deleteUnlessOwned(AppLocalDatabase.expenseTable, 'property_ref');
    final leftoverItems = await db.query(
      AppLocalDatabase.inventoryItemTable,
      columns: ['id'],
    );
    final itemIds = leftoverItems
        .map((row) => row['id'])
        .whereType<int>()
        .toList();
    if (itemIds.isEmpty) {
      await db.delete(AppLocalDatabase.inventoryMovementTable);
    } else {
      final placeholders = List.filled(itemIds.length, '?').join(',');
      await db.delete(
        AppLocalDatabase.inventoryMovementTable,
        where: 'item_local_id NOT IN ($placeholders)',
        whereArgs: itemIds,
      );
    }
  }
}
