import 'dart:async';
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

  Future<void> updateToolQuantity(int toolId, int quantityChange) async {
    final db = await database;
    await db.transaction((txn) async {
      // 현재 잔여 수량을 조회
      List<Map<String, dynamic>> toolList = await txn.query(
        'tools',
        where: 'id = ?',
        whereArgs: [toolId],
      );

      if (toolList.isNotEmpty) {
        int currentQuantity = toolList.first['quantity'];
        int newQuantity = currentQuantity + quantityChange;

        // 잔여 수량 업데이트
        await txn.update(
          'tools',
          {'quantity': newQuantity},
          where: 'id = ?',
          whereArgs: [toolId],
        );
      }
    });
  }

  Future<Uses?> getUseById(int id) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'uses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.length > 0) {
      return Uses.fromMap(maps.first);
    }
    return null;
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE tools (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      quantity INTEGER NOT NULL
    )
  ''');
    await db.execute('''
    CREATE TABLE uses (
      id INTEGER PRIMARY KEY,
      toolId INTEGER NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT,
      amount INTEGER NOT NULL,
      site_name TEXT NOT NULL,
      siteMan TEXT NOT NULL
    )
  ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await db.execute('''
        ALTER TABLE uses ADD COLUMN siteMan TEXT NOT NULL DEFAULT ''
      ''');
    }
  }

  Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'tools_database.db'),
      onCreate: _onCreate,
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

// 도구목록 삭제하기.
  Future<void> deleteTool(int toolId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'uses',
        where: 'id = ?',
        whereArgs: [toolId],
      );

      await txn.delete(
        'tools',
        where: 'id = ?',
        whereArgs: [toolId],
      );
    });
  }

  Future<int> insertUse(Uses use) async {
    Database db = await database;
    String? endDate =
        use.endDate != null ? use.endDate!.toIso8601String() : null;

    return await db.rawInsert(
        'INSERT OR REPLACE INTO uses (toolId, start_date, end_date, amount, site_name, siteMan) VALUES (?, ?, ?, ?, ?, ?)',
        [
          use.toolId,
          use.startDate.toIso8601String(),
          endDate,
          use.amount,
          use.siteName,
          use.siteMan
        ]);
  }

  Future<void> deleteUse(int id) async {
    final db = await database;
    await db.delete('uses', where: 'id = ?', whereArgs: [id]);
    _toolStreamController.add(null); // Emit an event when a use is deleted
  }

// 사용 내역 업데이트하기 (수정)
// FIXME:
//   사용내역 수정버튼이랑 연결.

  Future<void> updateUse(Uses use) async {
    final db = await database;
    await db.update(
      'uses',
      use.toMap(),
      where: 'id = ?',
      whereArgs: [use.id],
    );
    _toolStreamController.add(null); // Emit an event when a use is updated
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
        // null이 아닌 경우에만 String으로
        siteNames.removeWhere((name) => name.isEmpty); // 빈 문자열 제거
      }
      print('Fetched site names: $siteNames'); // 결과 출력
    } catch (e) {
      print('Error fetching site names: $e');
    }

    return siteNames;
  }
}
