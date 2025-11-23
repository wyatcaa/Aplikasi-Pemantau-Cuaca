import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location_model.dart'; 
import '../models/user_model.dart';

class DBService {
  static Database? _db;
  final int maxHistoryCount = 10;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE locations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            country TEXT,
            latitude REAL UNIQUE, 
            longitude REAL UNIQUE, 
            timezone TEXT,
            currency TEXT,
            updated_at INTEGER 
          )
        ''');

        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            email TEXT UNIQUE, 
            password TEXT
          )
        ''');
      },
    );
  }

  Future<void> registerUser(UserModel user) async {
    final db = await database;
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<UserModel?> loginUser(String email, String hashedPassword) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, hashedPassword],
    );

    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }
  
  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }
  
  Future<void> saveLocation(LocationModel location) async {
    final db = await database;
    final uniqueWhere = 'latitude = ? AND longitude = ?';
    final uniqueArgs = [location.latitude, location.longitude];

    final data = {...location.toMap(), 'updated_at': DateTime.now().millisecondsSinceEpoch};
    int count = await db.update('locations', data, where: uniqueWhere, whereArgs: uniqueArgs);

    if (count == 0) {
      await db.insert('locations', data);
    }

    final totalCount = await db.query('locations', columns: ['COUNT(*)']);
    final currentCount = Sqflite.firstIntValue(totalCount);

    if (currentCount != null && currentCount > maxHistoryCount) {
      final latest = await db.query('locations', columns: ['id'], orderBy: 'updated_at DESC', limit: maxHistoryCount);
      final latestIds = latest.map((e) => e['id']).toList();
      await db.delete('locations', where: 'id NOT IN (${latestIds.join(',')})');
    }
  }

  Future<List<LocationModel>> getLocations() async {
    final db = await database;
    final res = await db.query('locations', orderBy: 'updated_at DESC');
    return res.map((e) => LocationModel.fromMap(e)).toList(); 
  }

  Future<void> deleteLocation(int id) async {
    final db = await database;
    await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('locations');
  }

Future<void> updateUser(UserModel user) async {
  final db = await database;
  
  if (user.id == null) return; 
  final data = user.toMap(); 
  
  await db.update(
    'users',
    data,
    where: 'id = ?',
    whereArgs: [user.id],
    conflictAlgorithm: ConflictAlgorithm.rollback, 
  );
}


}