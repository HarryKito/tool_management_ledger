import 'package:flutter/material.dart';
import 'package:onetop_tool_management/DB/database_helper.dart';

class SiteDetailScreen extends StatefulWidget {
  final String siteName;

  SiteDetailScreen({required this.siteName});

  @override
  _SiteDetailScreenState createState() => _SiteDetailScreenState();
}
f
// 도구 사용목록 상세 페이지
class _SiteDetailScreenState extends State<SiteDetailScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> toolsUsedAtSite = [];

  @override
  void initState() {
    super.initState();
  }

// 도구 사용목록 상세 페이지 by 현장명 GUI init
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('현장: ${widget.siteName}'),
        ),
        body: Text("각 현장명에 따른 도구 사용 목록"));
  }
}
