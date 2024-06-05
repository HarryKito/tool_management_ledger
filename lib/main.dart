import 'package:flutter/material.dart';
import 'package:inventory/ToolScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '도구관리함',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ToolsScreen(),
    );
  }
}
