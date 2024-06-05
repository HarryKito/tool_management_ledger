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
  red(Colors.red); // 10

  final Color color;
  const ListColor(this.color);
}
