import 'package:sqflite/sqflite.dart';
import 'log_record.dart';
import 'log_level.dart';

class LogsRepository {
  final Database _db;

  LogsRepository(this._db);

  Future<int> insert(LogRecord record) async {
    return _db.insert(
      'logs',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LogRecord>> getRecent({
    int limit = 200,
    LogLevel? minLevel,
  }) async {
    final where = <String>[];
    final whereArgs = <Object?>[];

    if (minLevel != null) {
      where.add('level = ?');
      whereArgs.add(minLevel.name);
    }

    final rows = await _db.query(
      'logs',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return rows.map((e) => LogRecord.fromMap(e)).toList();
  }

  Future<List<LogRecord>> getByChainId(String chainId) async {
    final rows = await _db.query(
      'logs',
      where: 'chain_id = ?',
      whereArgs: [chainId],
      orderBy: 'timestamp ASC',
    );

    return rows.map((e) => LogRecord.fromMap(e)).toList();
  }

  Future<void> clear() async {
    await _db.delete('logs');
  }

  Future<void> deleteOlderThan(DateTime dt) async {
    await _db.delete(
      'logs',
      where: 'timestamp < ?',
      whereArgs: [dt.toIso8601String()],
    );
  }
}
