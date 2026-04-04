import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Local rent listing row persisted for the Rent hub (offline-first).
class RentPropertyRecord {
  const RentPropertyRecord({
    required this.id,
    required this.propertyLocation,
    required this.apartmentSuite,
    required this.propertyType,
    required this.rentAmount,
    required this.rentFrequency,
    required this.minRentalDuration,
    required this.createdAtMs,
    this.unitsJson = '',
  });

  final int id;
  final String propertyLocation;
  final String apartmentSuite;
  final String propertyType;
  final String rentAmount;
  final String rentFrequency;
  final String minRentalDuration;
  final int createdAtMs;
  /// JSON array of apartment units when `propertyType` is Apartment.
  final String unitsJson;

  factory RentPropertyRecord.fromMap(Map<String, Object?> m) {
    return RentPropertyRecord(
      id: m['id']! as int,
      propertyLocation: m['property_location'] as String? ?? '',
      apartmentSuite: m['apartment_suite'] as String? ?? '',
      propertyType: m['property_type'] as String? ?? '',
      rentAmount: m['rent_amount'] as String? ?? '',
      rentFrequency: m['rent_frequency'] as String? ?? '',
      minRentalDuration: m['min_rental_duration'] as String? ?? '',
      createdAtMs: m['created_at_ms'] as int? ?? 0,
      unitsJson: m['units_json'] as String? ?? '',
    );
  }

  Map<String, Object?> toInsertMap() => {
        'property_location': propertyLocation,
        'apartment_suite': apartmentSuite,
        'property_type': propertyType,
        'rent_amount': rentAmount,
        'rent_frequency': rentFrequency,
        'min_rental_duration': minRentalDuration,
        'created_at_ms': createdAtMs,
        'units_json': unitsJson,
      };
}

class RentPropertyLocalDataSource {
  static const _dbName = 'rent_properties.db';
  static const _table = 'rent_properties';
  static const _version = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_table ADD COLUMN units_json TEXT NOT NULL DEFAULT ""',
          );
        }
      },
    );
  }

  Future<int> insert(RentPropertyRecord row) async {
    final db = await database;
    return db.insert(_table, row.toInsertMap());
  }

  Future<List<RentPropertyRecord>> getAllNewestFirst() async {
    final db = await database;
    final maps = await db.query(_table, orderBy: 'created_at_ms DESC');
    return maps.map(RentPropertyRecord.fromMap).toList();
  }
}
