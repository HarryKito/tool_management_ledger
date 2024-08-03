import 'package:flutter/material.dart';
import 'package:onetop_tool_management/ToolScreen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// 프로그램 시작점.
//  DB : sqflite
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
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
