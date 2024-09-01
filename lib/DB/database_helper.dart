import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:onetop_tool_management/DB/models.dart';

// DB에 관한 클래스.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  final _toolStreamController = StreamController<void>.broadcast();

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();
  Stream<void> get toolStream => _toolStreamController.stream;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
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
      siteMan TEXT NOT NULL,
      borrower TEXT NOT NULL,
      isBorrow INTEGER NOT NULL
    )
  ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      await db.execute('''
      ALTER TABLE uses ADD COLUMN borrower TEXT NOT NULL DEFAULT ''
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

// 도구 삭제
  Future<void> deleteTool(int toolId) async {
    final db = await database;
    await db.transaction((txn) async {
      // 모든 관련 사용 기록 삭제
      await txn.delete(
        'uses',
        where: 'toolId = ?',
        whereArgs: [toolId],
      );

      await txn.delete(
        'tools',
        where: 'id = ?',
        whereArgs: [toolId],
      );
    });
  }

  Future<void> markAsReturned(int useId) async {
    final db = await database;

    await db.update(
      'uses',
      {'isBorrow': 0},
      where: 'id = ?',
      whereArgs: [useId],
    );

    _toolStreamController.add(null);
  }

// 반납 처리 후 날짜 기록
  Future<void> markAsReturnedWithDate(int id) async {
    final db = await this.database;
    await db.update(
      'uses',
      {
        'isBorrow': 0,
        'end_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertUse(Uses use) async {
    Database db = await database;
    String? endDate =
        use.endDate != null ? use.endDate!.toIso8601String() : null;
    use.isBorrow = 1;

    return await db.rawInsert(
        'INSERT OR REPLACE INTO uses (toolId, start_date, end_date, amount, site_name, siteMan, borrower, isBorrow) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          use.toolId,
          use.startDate.toIso8601String(),
          endDate,
          use.amount,
          use.siteName,
          use.siteMan,
          use.borrower,
          use.isBorrow
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

  Future<int> getTotalUsageByToolId(int toolId,
      {bool onlyBorrowed = false}) async {
    final db = await database;
    String whereClause = 'toolId = ?';
    List<dynamic> whereArgs = [toolId];

    if (onlyBorrowed) {
      whereClause += ' AND isBorrow = 1'; // 반납되지 않은 내역만 선택
    }

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM uses WHERE $whereClause',
      whereArgs,
    );

    return result.first['total'] != null ? result.first['total'] as int : 0;
  }

  // Future<int> getTotalUsageByToolId(int toolId) async {
  //   final db = await database;
  //   final result = await db.rawQuery(
  //       'SELECT SUM(amount) as total FROM uses WHERE toolId = ?', [toolId]);
  //   return result.first['total'] != null ? result.first['total'] as int : 0;
  // }

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
        siteNames.removeWhere((name) => name.isEmpty);
      }
      // print('Fetched site names: $siteNames'); // 결과 출력
    } catch (e) {
      print('Error fetching site names: $e');
    }

    return siteNames;
  }

  // 어떠한 현장명에 사용된 도구 목록
  Future<List<Map<String, dynamic>>> getToolUsageBySiteName(
      String siteName) async {
    final db = await this.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT u.id, t.name, u.start_date, u.end_date, u.amount AS used_amount, u.isBorrow
    FROM tools t
    JOIN uses u ON t.id = u.toolId
    WHERE u.site_name = ?
  ''', [siteName]);

    return maps;
  }

  Future<String?> getSiteManagerByName(String siteName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'uses',
      columns: ['siteMan'],
      where: 'site_name = ?',
      whereArgs: [siteName],
      limit: 1, // 하나의 결과만
    );

    if (maps.isNotEmpty) {
      return maps.first['siteMan'] as String?;
    }
    return null;
  }
}
