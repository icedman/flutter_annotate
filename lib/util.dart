import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Color colorCombine(Color a, Color b) {
  return Color.fromRGBO((a.red + b.red) >> 1, (a.green + b.green) >> 1,
      (a.blue + b.blue) >> 1, 1);
}

Offset getExtents(style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: "?", style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 0, maxWidth: double.infinity);
  double fw = textPainter.size.width;
  double fh = textPainter.size.height;
  return Offset(fw, fh);
}
