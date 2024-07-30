import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onetop_tool_management/DB/database_helper.dart';
import 'package:onetop_tool_management/DB/models.dart';
import 'package:onetop_tool_management/use_detail.dart';

class ToolsScreen extends StatefulWidget {
  @override
  _ToolsScreenState createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Tools> toolsList = [];
  List<Tools> filteredToolsList = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToolsList();
    searchController.addListener(_filterToolsList);
  }

  Future<void> _loadToolsList() async {
    List<Tools> tools = await dbHelper.getTools();
    for (var tool in tools) {
      int totalUsage = await dbHelper.getTotalUsageByToolId(tool.id!);
      tool.remainingQuantity = tool.quantity - totalUsage;
    }
    tools.sort((a, b) => a.name.compareTo(b.name));
    setState(() {
      toolsList = tools;
      filteredToolsList = tools; // 초기 목록 설정
    });
  }

  void _filterToolsList() {
    String searchQuery = searchController.text.toLowerCase();
    setState(() {
      filteredToolsList = toolsList
          .where((tool) => tool.name.toLowerCase().contains(searchQuery))
          .toList();
    });
  }

  void _addTool() async {
    if (nameController.text.isNotEmpty && quantityController.text.isNotEmpty) {
      Tools tool = Tools(
        name: nameController.text,
        quantity: int.parse(quantityController.text),
      );
      await dbHelper.insertTool(tool);
      nameController.clear();
      quantityController.clear();
      _loadToolsList();
    }
  }

  void _confirmDeleteTool(int id, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text('\'$name\'을(를) 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                _deleteTool(id);
                Navigator.of(context).pop();
              },
              child: Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTool(int id) async {
    await dbHelper.deleteTool(id);
    _loadToolsList();
  }

  void _editTool(Tools tool) {
    nameController.text = tool.name;
    quantityController.text = tool.quantity.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: '품명'),
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: '변경 수량'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    quantityController.text.isNotEmpty) {
                  tool.name = nameController.text;
                  tool.quantity = int.parse(quantityController.text);
                  dbHelper.updateTool(tool).then((_) {
                    _loadToolsList(); // 도구 수정 후 목록 다시 불러오기
                    Navigator.of(context).pop();
                  });
                }
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('도구 관리 대장'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: '품명 검색',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredToolsList.length,
              itemBuilder: (context, index) {
                Tools tool = filteredToolsList[index];
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(flex: 2, child: Text(tool.name)),
                      Spacer(),
                      Expanded(flex: 2, child: Text('수량: ${tool.quantity}')),
                      Spacer(),
                      Expanded(
                          flex: 2,
                          child: Text(
                              '불출량: ${tool.quantity - tool.remainingQuantity}')),
                      Spacer(),
                      Expanded(
                          flex: 2,
                          child: Text('잔여량: ${tool.remainingQuantity}')),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _editTool(tool),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _confirmDeleteTool(tool.id!, tool.name),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UseDetailScreen(toolId: tool.id!),
                      ),
                    ).then((_) {
                      _loadToolsList(); // 도구 사용 기록 수정 후 돌아왔을 때 목록 다시 불러오기
                    });
                  },
                );
              },
            ),
          ),
          // 도구 추가 입력란
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: '품명'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    decoration: InputDecoration(labelText: '수량'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTool,
                  child: Text('추가'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
