import 'package:flutter/material.dart';
import 'package:onetop_tool_management/DB/database_helper.dart';
import 'package:onetop_tool_management/DB/models.dart';

class SiteDetailScreen extends StatefulWidget {
  // 현장명 내용 입수
  final String siteName;
  SiteDetailScreen({required this.siteName});

  @override
  _SiteDetailScreenState createState() => _SiteDetailScreenState();
}

// 도구 사용목록 상세 페이지
class _SiteDetailScreenState extends State<SiteDetailScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> toolsAtSite = [];

  @override
  void initState() {
    super.initState();
    _loadToolsAtSite();
  }

  Future<void> _loadToolsAtSite() async {
    List<Map<String, dynamic>> tools =
        await dbHelper.getToolUsageBySiteName(widget.siteName);
    setState(() {
      toolsAtSite = tools;
    });
  }

// 도구 사용목록 상세 페이지 by 현장명 GUI init
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('현장: ${widget.siteName}'),
      ),
      body: ListView.builder(
        itemCount: toolsAtSite.length,
        itemBuilder: (context, index) {
          final tool = toolsAtSite[index];
          return ListTile(
            title: Text(tool['name']),
            subtitle: Text('불출량: ${tool['used_amount']}'),
          );
        },
      ),
    );
  }
}
