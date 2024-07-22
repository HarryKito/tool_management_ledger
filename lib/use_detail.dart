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
  DateTimeRange? selectedDateRange;
  List<Uses> toolUses = [];
  List<String> siteNames = [];
  String toolName = '';
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

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedDateRange ??
          DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now().add(Duration(days: 1)),
          ),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  void _recordUsage() async {
    final int amount = int.tryParse(amountController.text) ?? 0;
    final String siteName = siteNameController.text.isNotEmpty
        ? siteNameController.text
        : selectedSiteName ?? 'NULL';
    final String siteMan = siteManController.text;

    print('Selected Date Range: $selectedDateRange');
    print('Amount: $amount');
    print('Site Name: $siteName');
    print('Site Man: $siteMan');

    if (selectedDateRange != null &&
        amount > 0 &&
        siteName.isNotEmpty &&
        siteMan.isNotEmpty) {
      Uses use = Uses(
        toolId: widget.toolId,
        startDate: selectedDateRange!.start,
        endDate: selectedDateRange?.end, // 종료일이 null일 수 있음
        amount: amount,
        siteName: siteName,
      );
      print('Attempting to insert use: $use'); // 디버깅 출력
      await dbHelper.insertUse(use);
      _fetchToolUses();
      amountController.clear();
      siteNameController.clear();
      siteManController.clear();
      selectedDateRange = null;
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

  void _showDeleteConfirmationDialog(BuildContext context, Uses use) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text(
            '사용 내역을 삭제하시겠습니까?\n'
            '사용 기간: ${use.startDate.toLocal().toString().split(' ')[0]} ~ ${use.endDate?.toLocal().toString().split(' ')[0] ?? '종료일 없음'}\n'
            '사용량: ${use.amount}\n'
            '현장명: ${use.siteName}',
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
                    onTap: () => _selectDateRange(context),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(
                          text: selectedDateRange != null
                              ? "${selectedDateRange!.start.toLocal().toString().split(' ')[0]} ~ ${selectedDateRange?.end?.toLocal().toString().split(' ')[0] ?? ''}"
                              : '',
                        ),
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: '사용 시작일',
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
                  Uses use = toolUses[index];
                  return ListTile(
                    title: Text(
                        '사용 일자: ${use.startDate.toLocal().toString().split(' ')[0]}'),
                    subtitle: Text('사용량: ${use.amount}\n현장명: ${use.siteName}'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () =>
                          _showDeleteConfirmationDialog(context, use),
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
