import 'package:flutter/material.dart';

// 리스트 구현에 사용할 컬러코드 (0 ~ 100%)
enum ListColor {
  lightBlue(Colors.lightBlue), // 1
  skyBlue(Colors.lightBlueAccent), // 2
  cyan(Colors.cyan), // 3
  teal(Colors.teal), // 4
  lime(Colors.lime), // 5
  yellow(Colors.yellow), // 6
  amber(Colors.amber), // 7
  orange(Colors.orange), // 8
  deepOrange(Colors.deepOrange), // 9
  red(Colors.red); // 10% 미만

  final Color color;
  const ListColor(this.color);

  static Color getColorForPercentage(double percentage) {
    if (percentage <= 10) return ListColor.red.color;
    if (percentage <= 20) return ListColor.deepOrange.color;
    if (percentage <= 30) return ListColor.orange.color;
    if (percentage <= 40) return ListColor.amber.color;
    if (percentage <= 50) return ListColor.yellow.color;
    if (percentage <= 60) return ListColor.lime.color;
    if (percentage <= 70) return ListColor.teal.color;
    if (percentage <= 80) return ListColor.cyan.color;
    if (percentage <= 90) return ListColor.skyBlue.color;
    return ListColor.lightBlue.color;
  }
}
