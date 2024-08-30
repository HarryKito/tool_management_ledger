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
  final TextEditingController borrowerController = TextEditingController();
  final DatabaseHelper dbHelper = DatabaseHelper();
  DateTime? selectedDate;
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
    final String siteName = siteNameController.text;
    final String siteMan = siteManController.text;
    final String borrower = borrowerController.text;
    final int isBorrow = 0;

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
        borrower: borrower,
        isBorrow: isBorrow,
      );
      await dbHelper.insertUse(use);

      // 사용량을 총량에서 차감
      setState(() {
        toolQuantity -= amount;
      });

      _fetchToolUses();
      amountController.clear();
      siteNameController.clear();
      siteManController.clear();
      borrowerController.clear();
      selectedDate = null;
      setState(() {
        selectedSiteName = null;
      });
    } else {
      print('Invalid input data'); // 디버깅 출력
      print("site name : ${siteName}");
    }
  }

  void _deleteUse(int useId) async {
    await dbHelper.deleteUse(useId);
    _fetchToolUses();
  }

  void _markAsReturned(int index) async {
    setState(() {
      toolUses[index].isBorrow = 0;
    });

    await dbHelper.updateUse(toolUses[index]);
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
          title: Text('반납 확인'),
          content: Text(
            '반출 내역을 삭제하시겠습니까?\n'
            '불출일: ${use.startDate.toLocal().toString().split(' ')[0]} \n'
            '반출량: ${use.amount}\n'
            '현장명: ${use.siteName}\n'
            '현장 담당자: ${use.siteMan}\n'
            '반출자: ${use.borrower}',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('반납처리'),
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
        title: Text('공도구 반출 기록'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '선택 도구명 : $toolName',
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
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return siteNames.where((String option) {
                        return option
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) async {
                      setState(() {
                        selectedSiteName = selection;
                        siteNameController.text = selection;
                      });

                      // DB로부터 현장 담당자 수집
                      String? siteMan =
                          await dbHelper.getSiteManagerByName(selection);
                      if (siteMan != null) {
                        setState(() {
                          siteManController.text = siteMan;
                        });
                      }
                    },
                    fieldViewBuilder: (BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted) {
                      fieldTextEditingController.addListener(() {
                        siteNameController.text =
                            fieldTextEditingController.text;
                      });

                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: InputDecoration(
                          labelText: '현장명',
                        ),
                      );
                    },
                  ),
                ),
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
                  child: TextField(
                    controller: borrowerController, // 추가된 필드
                    decoration: InputDecoration(
                      labelText: '반출자',
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
              '공도구 반출 내역',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                  itemCount: toolUses.length,
                  itemBuilder: (BuildContext context, int index) {
                    Uses use = toolUses[index];
                    return ListTile(
                      title: Text(
                        '${use.startDate.toLocal().toString().split(' ')[0]} - ${use.siteName}',
                        style: TextStyle(
                          decoration: use.isBorrow == 0
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle:
                          Text('현장 담당자: ${use.siteMan} / 반출자: ${use.borrower}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: use.isBorrow == 0
                                ? null
                                : () {
                                    _markAsReturned(index); // 각 항목의 index를 전달
                                  },
                            child: Text(
                              '반납',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Tooltip(
                            message: '행 삭제',
                            child: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () =>
                                  _showDeleteConfirmationDialog(context, use),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
