// ----- 도구 모델 -----
//
// 품번
// 품명
// 수량
// 잔량
class Tools {
  int? id;
  String name;
  int quantity;
  int remainingQuantity;

  Tools(
      {this.id,
      required this.name,
      required this.quantity,
      this.remainingQuantity = 0});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
    };
  }

  factory Tools.fromMap(Map<String, dynamic> map) {
    return Tools(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      remainingQuantity: 0,
    );
  }

  // 잔량
  String getStockStatus() {
    if (remainingQuantity == 0) {
      return 'empty';
    } else if (remainingQuantity < quantity * 0.2) {
      return 'low';
    } else {
      return 'normal';
    }
  }
}

// ----- 사용 기록모델 -----
//
// 사용번호
// 품번
// 시작일
// 종료일
// 사용량
// 사용처
class Uses {
  final int? id;
  final int toolId;
  final DateTime startDate;
  final DateTime? endDate;
  final int amount;
  final String siteName;
  final String siteMan;

  Uses({
    this.id,
    required this.toolId,
    required this.startDate,
    this.endDate,
    required this.amount,
    required this.siteName,
    required this.siteMan,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'toolId': toolId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'amount': amount,
      'site_name': siteName,
      'siteMan': siteMan,
    };
  }

  factory Uses.fromMap(Map<String, dynamic> map) {
    return Uses(
      id: map['id'],
      toolId: map['toolId'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      amount: map['amount'],
      siteName: map['site_name'],
      siteMan: map['siteMan'],
    );
  }
}
