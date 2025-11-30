import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static const int _dbVersion = 1;

  Database? _db;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'coupons.db');

    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE coupons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        used INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE coupon_jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mail TEXT NOT NULL,
        cookie_header TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        status INTEGER NOT NULL,
        tries INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE coupon_jobs_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mail TEXT NOT NULL,
        cookie_header TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        finished_at INTEGER NOT NULL,
        success INTEGER NOT NULL,
        error TEXT
      )
    ''');
  }
}
