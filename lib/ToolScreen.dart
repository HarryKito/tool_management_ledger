import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onetop_tool_management/DB/database_helper.dart';
import 'package:onetop_tool_management/DB/models.dart';
import 'package:onetop_tool_management/use_detail.dart';
import 'package:onetop_tool_management/SiteDetail.dart'; // 새로운 화면 import

class ToolsScreen extends StatefulWidget {
  @override
  _ToolsScreenState createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Tools> toolsList = [];
  List<Tools> filteredToolsList = [];
  List<String> siteNames = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToolsList();
    searchController.addListener(_filterToolsList);
    _loadSiteNames();
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
      filteredToolsList = tools;
    });
  }

  Future<void> _loadSiteNames() async {
    List<String> names = await dbHelper.getAllSiteNames();
    setState(() {
      siteNames = names;
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
      String newName = nameController.text;
      bool isDuplicate = toolsList.any((tool) => tool.name == newName);

      if (isDuplicate) {
        _showDuplicateWarning(newName);
      } else {
        Tools tool = Tools(
          name: newName,
          quantity: int.parse(quantityController.text),
        );
        await dbHelper.insertTool(tool);
        nameController.clear();
        quantityController.clear();
        await _loadToolsList();
        await _loadSiteNames(); // Load site names after adding a tool
      }
    }
  }

  void _showDuplicateWarning(String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('중복된 품명'),
          content: Text('\'$name\'(은)는 이미 존재합니다. 다른 이름을 사용해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTool(int id, String name) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text('\'$name\'항목을 정말 삭제하시겠습니까?'),
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
    await _loadToolsList();
    await _loadSiteNames(); // Load site names after deleting a tool
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
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    quantityController.text.isNotEmpty) {
                  tool.name = nameController.text;
                  tool.quantity = int.parse(quantityController.text);
                  await dbHelper.updateTool(tool);
                  await _loadToolsList(); // 도구 수정 후 목록 다시 불러오기
                  await _loadSiteNames(); // Load site names after editing a tool
                  Navigator.of(context).pop();
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
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
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
                            Expanded(
                                flex: 2, child: Text('수량: ${tool.quantity}')),
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
                          onPressed: () =>
                              _confirmDeleteTool(tool.id!, tool.name),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UseDetailScreen(toolId: tool.id!),
                            ),
                          ).then((_) async {
                            await _loadToolsList(); // 도구 사용 기록 수정 후 돌아왔을 때 목록 다시 불러오기
                            await _loadSiteNames(); // Load site names after returning from use details screen
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
                          onSubmitted: (value) => _addTool(),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          decoration: InputDecoration(labelText: '수량'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onSubmitted: (value) => _addTool(),
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
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.grey,
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '현장명 목록',
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: siteNames.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(siteNames[index]),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SiteDetailScreen(siteName: siteNames[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
