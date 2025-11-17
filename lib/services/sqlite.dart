import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SqliteService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    try {
      print('=== INITIALIZING SQLITE WITH FFI ===');
      
      // Initialize FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      String dbPath = await _getDatabasePath();
      print('Database path: $dbPath');

      _database = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (Database db, int version) async {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS test_data(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT,
                description TEXT,
                status INTEGER
              )
            ''');
          },
        ),
      );

      print('=== DATABASE INITIALIZED SUCCESSFULLY ===');
      return _database!;
    } catch (e) {
      print('=== DATABASE INITIALIZATION FAILED ===');
      print('Error: $e');
      rethrow;
    }
  }

  Future<String> _getDatabasePath() async {
    try {
      Directory directory;

      if (Platform.isLinux) {
        String? homeDir = Platform.environment['HOME'];
        if (homeDir != null) {
          directory = Directory('$homeDir/.local/share/todo_app');
        } else {
          directory = await getApplicationSupportDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      return '${directory.path}/todo_app.db';
    } catch (e) {
      print('Error getting database path: $e');
      return 'todo_app.db';
    }
  }

  Future<List<Map<String, dynamic>>> getAll(String query, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(query, arguments);
  }

  Future<int> execute(String query, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(query, arguments);
  }

  Future<int> update(String query, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(query, arguments);
  }

  Future<int> delete(String query, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawDelete(query, arguments);
  }

  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final dbPath = await _getDatabasePath();
      final dbFile = File(dbPath);
      final exists = await dbFile.exists();
      
      return {
        'path': dbPath,
        'exists': exists,
        'size': exists ? await dbFile.length() : 0,
        'directory': dbFile.parent.path,
        'directory_exists': await dbFile.parent.exists(),
        'platform': Platform.operatingSystem,
        'home_dir': Platform.environment['HOME'],
        'sqlite_type': 'bundled_ffi',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}