import 'dart:async';
// import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:onetop_tool_management/DB/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  final _toolStreamController = StreamController<void>.broadcast();

  DatabaseHelper._internal();

  Stream<void> get toolStream => _toolStreamController.stream;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'tools_database.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE tools(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, quantity INTEGER)',
        );
        await db.execute(
          'CREATE TABLE uses(id INTEGER PRIMARY KEY AUTOINCREMENT, toolId INTEGER, start_date TEXT, end_date TEXT, amount INTEGER, site_name TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> insertTool(Tools tool) async {
    final db = await database;
    await db.insert('tools', tool.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    _toolStreamController.add(null); // Emit an event when a tool is added
  }

  Future<void> updateTool(Tools tool) async {
    final db = await database;
    await db.update(
      'tools',
      tool.toMap(),
      where: 'id = ?',
      whereArgs: [tool.id],
    );
    _toolStreamController.add(null); // Emit an event when a tool is updated
  }

  Future<List<Tools>> getTools() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tools');

    return List.generate(maps.length, (i) {
      return Tools.fromMap(maps[i]);
    });
  }

  Future<void> deleteTool(int id) async {
    final db = await database;
    await db.delete('tools', where: 'id = ?', whereArgs: [id]);
    _toolStreamController.add(null); // Emit an event when a tool is deleted
  }

  Future<void> insertUse(Uses use) async {
    final db = await database;
    await db.insert('uses', use.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    _toolStreamController.add(null); // Emit an event when a use is added
  }

  Future<void> deleteUse(int id) async {
    final db = await database;
    await db.delete('uses', where: 'id = ?', whereArgs: [id]);
    _toolStreamController.add(null); // Emit an event when a use is deleted
  }

  Future<List<Uses>> getUsesByToolId(int toolId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('uses', where: 'toolId = ?', whereArgs: [toolId]);

    return List.generate(maps.length, (i) {
      return Uses.fromMap(maps[i]);
    });
  }

  Future<Tools?> getToolById(int toolId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('tools', where: 'id = ?', whereArgs: [toolId]);

    if (maps.isNotEmpty) {
      return Tools.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> getTotalUsageByToolId(int toolId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT SUM(amount) as total FROM uses WHERE toolId = ?', [toolId]);
    return result.first['total'] != null ? result.first['total'] as int : 0;
  }
}
