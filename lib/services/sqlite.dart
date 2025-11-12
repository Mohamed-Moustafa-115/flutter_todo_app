import 'package:sqlite_async/sqlite_async.dart';

class SqliteService {
  final _migration = SqliteMigrations()
  ..add(SqliteMigration(2, (tx) async {
    await tx.execute(
        'CREATE TABLE IF NOT EXISTS test_data(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, status Integer)');
  }));
  final _db = SqliteDatabase(path: 'test.db');

  Future <SqliteDatabase> initDataBase() async {
    await _migration.migrate(_db);
    return _db;
  }
}