import 'package:flutter/material.dart';
import 'package:onetop_tool_management/DB/database_helper.dart';

class SiteDetailScreen extends StatefulWidget {
  final String siteName;
  SiteDetailScreen({required this.siteName});

  @override
  _SiteDetailScreenState createState() => _SiteDetailScreenState();
}

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

  Future<void> _deleteUsage(int id) async {
    await dbHelper.deleteUse(id);
    await _loadToolsAtSite(); // Reload the list after deletion
  }

  String formatDate(String? date) {
    if (date == null) {
      return 'N/A';
    }
    final DateTime dateTime = DateTime.parse(date);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('현장: ${widget.siteName}'),
      ),
      body: ListView.builder(
        itemCount: toolsAtSite.length,
        itemBuilder: (context, index) {
          final toolUsage = toolsAtSite[index];

          final toolName = toolUsage['name'] as String;
          final usedAmount = toolUsage['used_amount'] as int;
          final startDate = toolUsage['start_date'] as String?;
          final usageId = toolUsage['id'] as int;

          return ListTile(
              title: Text(toolName),
              subtitle: Text('불출량: $usedAmount\n불출일: ${formatDate(startDate)}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                TextButton(
                  onPressed: () {
                    // FIXME: 반납처리, 반납처리 후 취소선.
                    // TODO: use_detail과 마잔가지로 반납기능 구현
                    print('반납처리 기능구현');
                  },
                  child: Text(
                    '반납',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Tooltip(
                  message: "행 삭제",
                  child: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('삭제 확인'),
                            content: Text('이 항목을 삭제하시겠습니까?'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('취소'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('삭제'),
                                onPressed: () async {
                                  await _deleteUsage(usageId);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                )
              ]));
        },
      ),
    );
  }
}
