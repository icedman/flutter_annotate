import 'package:path/path.dart';
import 'package:flutter/material.dart';

Color colorCombine(Color a, Color b) {
  return Color.fromRGBO((a.red + b.red) >> 1, (a.green + b.green) >> 1,
      (a.blue + b.blue) >> 1, 1);
}
