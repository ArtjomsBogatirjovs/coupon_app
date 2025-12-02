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
      create table coupons (
        id integer primary key autoincrement,
        title text not null,
        link text,
        code text not null,
        created_at text not null,
        used integer not null
      )
    ''');

    await db.execute('''
      create table coupon_jobs (
        id integer primary key autoincrement,
        mail text not null,
        cookie_header text not null,
        created_at integer not null,
        status integer not null,
        tries integer not null
      )
    ''');

    await db.execute('''
      create table emails (
        mail text primary key,
        last_sent integer not null,
        last_sent_basic_mail integer,
        times_sent integer not null default 1,
        is_gmail integer not null check (is_gmail IN (0,1))
      )
    ''');
  }
}
