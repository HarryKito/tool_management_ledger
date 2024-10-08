import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onetop_tool_management/DB/database_helper.dart';
import 'package:onetop_tool_management/DB/models.dart';
import 'package:onetop_tool_management/use_detail.dart';
import 'package:onetop_tool_management/SiteDetail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ToolsScreen extends StatefulWidget {
  @override
  _ToolsScreenState createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> with WidgetsBindingObserver {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Tools> toolsList = [];
  List<Tools> filteredToolsList = [];
  List<String> siteNames = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  double _leftPanelWidth = 0.6;
  double _rightPanelWidth = 0.2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadToolsList();
    searchController.addListener(_filterToolsList);
    _loadSiteNames();
    _loadNote();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadToolsList();
      _loadSiteNames();
    }
  }

  Future<void> _loadToolsList() async {
    List<Tools> tools = await dbHelper.getTools();
    for (var tool in tools) {
      int totalUsage =
          await dbHelper.getTotalUsageByToolId(tool.id!, onlyBorrowed: true);
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

  Future<void> _loadNote() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedNote = prefs.getString('note') ?? '';
    noteController.text = savedNote;
  }

  Future<void> _saveNote() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('note', noteController.text);
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
        await _loadSiteNames();
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
    await _loadSiteNames();
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
                  await _loadToolsList();
                  await _loadSiteNames();
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
        title: Text('공구, 자재 입출고 관리대장'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Container(
                width: constraints.maxWidth * _leftPanelWidth,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: '공구/자재 검색',
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
                                    flex: 2,
                                    child: Text('수량: ${tool.quantity}')),
                                Spacer(),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        '불출량: ${tool.quantity - tool.remainingQuantity}')),
                                Spacer(),
                                Expanded(
                                    flex: 2,
                                    child:
                                        Text('잔여량: ${tool.remainingQuantity}')),
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
                                await _loadToolsList();
                                await _loadSiteNames();
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              decoration: InputDecoration(labelText: '공도구명'),
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
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _leftPanelWidth += details.delta.dx / constraints.maxWidth;
                    if (_leftPanelWidth < 0.3) _leftPanelWidth = 0.3;
                    if (_leftPanelWidth > 0.6) _leftPanelWidth = 0.6;
                  });
                },
                child: VerticalDivider(
                  width: 5,
                  thickness: 1,
                  color: Colors.black,
                ),
              ),
              Container(
                width: constraints.maxWidth * _rightPanelWidth,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '현장명 목록',
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
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
                                  builder: (context) => SiteDetailScreen(
                                      siteName: siteNames[index]),
                                ),
                              ).then((_) async {
                                await _loadToolsList();
                                await _loadSiteNames();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // GestureDetector(
              //   onHorizontalDragUpdate: (details) {
              //     setState(() {
              //       _rightPanelWidth -= details.delta.dx / constraints.maxWidth;
              //       if (_rightPanelWidth < 0.2) _rightPanelWidth = 0.2;
              //       if (_rightPanelWidth > 0.4) _rightPanelWidth = 0.4;
              //     });
              //   },
              //   child: VerticalDivider(
              //     width: 5,
              //     thickness: 1,
              //     color: Colors.black,
              //   ),
              // ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '메모장',
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: noteController,
                          maxLines: null,
                          expands: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '메모를 입력하세요...',
                          ),
                          onChanged: (value) => _saveNote(),
                        ),
                      ),
                    ),
                    // ElevatedButton(
                    //   onPressed: () async {
                    //     noteController.clear();
                    //     await _saveNote();
                    //   },
                    //   child: Text('메모 초기화'),
                    // ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
