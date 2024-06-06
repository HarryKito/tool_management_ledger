import 'dart:io';

import 'package:flutter/material.dart';
import 'package:onetop_tool_management/ToolScreen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: "Test",
      title: '도구관리함',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ToolsScreen(),
    );
  }
}
