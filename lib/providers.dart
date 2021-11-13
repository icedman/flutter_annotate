import 'dart:ffi';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'annotate.dart';

class EditorModel extends ChangeNotifier {
  AnnotateDoc? doc;
  Color color = Colors.red;
  int _highlightIndex = -1;
  List<HL> hl = <HL>[];

  void beginHighlight(int index) {
    _highlightIndex = index;
    notifyListeners();
  }

  void endHighlight() {
    _highlightIndex = -1;
    notifyListeners();
  }

  int currentHighlight() {
    return _highlightIndex;
  }

  void deleteHighlight(int index) {
    hl.removeAt(index);
    print(hl.length);
    endHighlight();
  }

  void recolor(int index, Color color) {
    this.color = color;
    hl[index].color = color;
    notifyListeners();
  }
}
