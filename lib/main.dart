import 'package:flutter/material.dart';
import 'package:onetop_tool_management/ToolScreen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:onetop_tool_management/DB/database_helper.dart';

// 프로그램 시작점.
//  DB : sqflite
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // DB 경로
  final dbHelper = DatabaseHelper.instance;
  final db = await dbHelper.database;
  final databasePath = db.path;

  print('DB 경로: $databasePath');

  // Application 실행.
  runApp(const MyApp());
}

// Flutter GUI 진입.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 도구 관리함
    return MaterialApp(
      title: '도구관리함',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // 도구 관리함 메인 페이지 (도구 관리 대장)
      home: ToolsScreen(),
    );
  }
}
