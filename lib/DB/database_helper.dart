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

// 모든 현장명 수집
// 현장명 목록 불러올 떄 사용
  Future<List<String>> getAllSiteNames() async {
    final db = await database;
    List<String> siteNames = [];

    try {
      var result = await db.rawQuery('SELECT DISTINCT site_name FROM uses');
      if (result.isNotEmpty) {
        siteNames = result
            .map((row) =>
                row['site_name'] != null ? row['site_name'] as String : '')
            .toList();
        // null이 아닌 경우에만 String으로 변환
        siteNames.removeWhere((name) => name.isEmpty); // 빈 문자열 제거
      }
      print('Fetched site names: $siteNames'); // 결과 출력
    } catch (e) {
      print('Error fetching site names: $e');
    }

    return siteNames;
  }
}
