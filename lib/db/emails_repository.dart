import 'package:sqflite/sqflite.dart';
import '../models/email.dart';

class EmailsRepository {
  final Database db;

  EmailsRepository(this.db);

  Future<void> upsert(EmailEntry entry) async {
    await db.insert(
      'emails',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<EmailEntry?> get(String mail) async {
    final res = await db.query(
      'emails',
      where: 'mail = ?',
      whereArgs: [mail],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return EmailEntry.fromMap(res.first);
  }

  Future<void> clear() async {
    await db.delete('emails');
  }
}
