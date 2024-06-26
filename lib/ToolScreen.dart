import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onetop_tool_management/DB/database_helper.dart';
import 'package:onetop_tool_management/DB/models.dart';
import 'package:onetop_tool_management/use_detail.dart';
import 'package:onetop_tool_management/design/colors.dart';

class ToolsScreen extends StatefulWidget {
  @override
  _ToolsScreenState createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<Tools> toolsList = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshToolsList();
  }

  Future<void> _refreshToolsList() async {
    List<Tools> tools = await dbHelper.getTools();
    for (var tool in tools) {
      int totalUsage = await dbHelper.getTotalUsageByToolId(tool.id!);
      tool.remainingQuantity = tool.quantity - totalUsage;
    }
    setState(() {
      toolsList = tools;
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
      _refreshToolsList();
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
    _refreshToolsList();
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
                decoration: InputDecoration(labelText: '수량'),
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
                  dbHelper.updateTool(tool);
                  _refreshToolsList();
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

  Color _getBackgroundColor(Tools tool) {
    double percentage = (tool.remainingQuantity / tool.quantity) * 100;
    return ListColor.getColorForPercentage(percentage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('도구 관리 대장'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<void>(
              stream: dbHelper.toolStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  _refreshToolsList();
                }
                return ListView.builder(
                  itemCount: toolsList.length,
                  itemBuilder: (context, index) {
                    Tools tool = toolsList[index];
                    return ListTile(
                      tileColor: _getBackgroundColor(tool), // 배경색 설정
                      title: Text(
                        '${tool.name} (수량: ${tool.quantity}, 잔량: ${tool.remainingQuantity})',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editTool(tool),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () =>
                                _confirmDeleteTool(tool.id!, tool.name),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UseDetailScreen(toolId: tool.id!),
                          ),
                        );
                      },
                    );
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
