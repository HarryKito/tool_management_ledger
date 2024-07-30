import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onetop_tool_management/DB/database_helper.dart';
import 'package:onetop_tool_management/DB/models.dart';

class UseDetailScreen extends StatefulWidget {
  final int toolId;

  UseDetailScreen({required this.toolId});

  @override
  _UseDetailScreenState createState() => _UseDetailScreenState();
}

class _UseDetailScreenState extends State<UseDetailScreen> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController siteNameController = TextEditingController();
  final TextEditingController siteManController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();
  DateTime? selectedDate; // DateTimeRange를 DateTime으로 변경
  List<Uses> toolUses = [];
  List<String> siteNames = [];
  String toolName = '';
  int toolQuantity = 0;
  String? selectedSiteName;

  @override
  void initState() {
    super.initState();
    _fetchToolData();
    _fetchSiteNames();
  }

  void _fetchToolData() async {
    Tools? tool = await dbHelper.getToolById(widget.toolId);
    if (tool != null) {
      setState(() {
        toolName = tool.name;
        toolQuantity = tool.quantity;
      });
    }
    _fetchToolUses();
  }

  void _fetchToolUses() async {
    List<Uses> uses = await dbHelper.getUsesByToolId(widget.toolId);
    setState(() {
      toolUses = uses;
    });
  }

  void _fetchSiteNames() async {
    List<String> names = await dbHelper.getAllSiteNames();
    setState(() {
      siteNames = names;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _recordUsage() async {
    final int amount = int.tryParse(amountController.text) ?? 0;
    final String siteName = siteNameController.text.isNotEmpty
        ? siteNameController.text
        : selectedSiteName ?? 'NULL';
    final String siteMan = siteManController.text;

    if (selectedDate != null &&
        amount > 0 &&
        siteName.isNotEmpty &&
        siteMan.isNotEmpty) {
      if (amount > toolQuantity) {
        _showWarningDialog(context, '불출량이 현재 수량을 초과합니다.');
        return;
      }
      Uses use = Uses(
        toolId: widget.toolId,
        startDate: selectedDate!,
        endDate: null, // 종료일 없음
        amount: amount,
        siteName: siteName,
        siteMan: siteMan,
      );
      await dbHelper.insertUse(use);

      // 사용량을 툴의 총량에서 차감
      setState(() {
        toolQuantity -= amount;
      });

      _fetchToolUses();
      amountController.clear();
      siteNameController.clear();
      siteManController.clear();
      selectedDate = null;
      setState(() {
        selectedSiteName = null;
      });
    } else {
      print('Invalid input data'); // 디버깅 출력
    }
  }

  void _deleteUse(int useId) async {
    await dbHelper.deleteUse(useId);
    _fetchToolUses();
  }

  void _showWarningDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('경고'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Uses use) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text(
            '사용 내역을 삭제하시겠습니까?\n'
            '불출일: ${use.startDate.toLocal().toString().split(' ')[0]} \n'
            '사용량: ${use.amount}\n'
            '현장명: ${use.siteName}\n'
            '현장 담당자: ${use.siteMan}',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('삭제'),
              onPressed: () {
                _deleteUse(use.id!);
                Navigator.of(context).pop();
              },
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
        title: Text('도구 사용 기록'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '선택 제품명 : $toolName',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            // FIXME: BUG FIX. (issue on README)
            // Text(
            //   '잔여 수량 : $toolQuantity',
            //   style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            // ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: '수량',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                SizedBox(width: 10),
                // 현장명
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return siteNames.where((String option) {
                        return option
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      setState(() {
                        selectedSiteName = selection;
                        siteNameController.text = selection;
                      });
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted) {
                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          labelText: '현장명',
                        ),
                        onChanged: (String value) {
                          setState(() {
                            selectedSiteName = null;
                          });
                        },
                      );
                    },
                    optionsViewBuilder: (BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: Container(
                            width: MediaQuery.of(context).size.width / 3,
                            child: ListView.builder(
                              padding: EdgeInsets.all(8.0),
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return GestureDetector(
                                  onTap: () {
                                    onSelected(option);
                                  },
                                  child: ListTile(
                                    title: Text(option),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 여기까지 현장명
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: siteManController,
                    decoration: InputDecoration(
                      labelText: '현장 담당자',
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(
                          text: selectedDate != null
                              ? selectedDate!.toLocal().toString().split(' ')[0]
                              : '',
                        ),
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: '불출일',
                          border: InputBorder.none,
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _recordUsage,
                  child: Text('저장'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              '도구 사용 내역',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: toolUses.length,
                itemBuilder: (context, index) {
                  final use = toolUses[index];
                  return ListTile(
                    title: Text(
                      '현장명: ${use.siteName} (담당자: ${use.siteMan})',
                    ),
                    subtitle: Text(
                      '불출일: ${use.startDate.toLocal().toString().split(' ')[0]}, 사용량: ${use.amount}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _showDeleteConfirmationDialog(context, use);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
