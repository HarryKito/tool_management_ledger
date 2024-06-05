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
      remainingQuantity: 0, // Default value, to be calculated later
    );
  }
}

class Uses {
  int? id;
  int toolId;
  DateTime startDate;
  DateTime endDate;
  int amount;
  String siteName;

  Uses({
    this.id,
    required this.toolId,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.siteName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'toolId': toolId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'amount': amount,
      'site_name': siteName,
    };
  }

  factory Uses.fromMap(Map<String, dynamic> map) {
    return Uses(
      id: map['id'],
      toolId: map['toolId'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      amount: map['amount'],
      siteName: map['site_name'],
    );
  }
}
