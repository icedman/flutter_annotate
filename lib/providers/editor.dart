import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' show join;

import '../constants.dart';
import '../editor.dart';
import '../annotate.dart';
import '../cache.dart';
import '../util.dart';

const Color selectionColor = Color.fromRGBO(0xc0, 0xc0, 0xc0, 1);

class EditorModel extends ChangeNotifier {
  EditorModel({AnnotateDoc? this.doc = null}) {
    if (this.doc != null) {
      this.colors = this.doc?.colors ?? [];
    }
  }

  AnnotateDoc? doc;

  bool enableDocTool = true;
  bool enableHighlight = false;
  int _highlightIndex = -1;
  Color _color = Colors.black;
  int _colorIndex = 0;
  HL selection = HL();
  bool selectTag = false;

  List<Color> colors = <Color>[
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple
  ];

  Color currentColor() {
    if (_color == Colors.black) {
      _color = colors[0];
    }
    return _color;
  }

  void addHighlight() {
    selection.color = currentColor();
    selection.colorIndex = _colorIndex;
    doc?.hl.add(selection);
    selectHighlight(count() - 1);
    selection = HL();
    notifyListeners();
    // print(doc?.hl.length);
  }

  void selectHighlight(int index) {
    _highlightIndex = index;
    selection = HL();
    notifyListeners();
  }

  void deleteHighlight(int index) {
    if (index != -1 && index < count()) {
      doc?.hl.removeAt(index);
      _highlightIndex = -1;
      notifyListeners();
    }
  }

  int count() {
    return doc?.hl.length ?? 0;
  }

  int currentHighlight() {
    return _highlightIndex;
  }

  void toggleHighlight() {
    enableHighlight = !enableHighlight;
    if (enableHighlight && hasSelection()) {
      addHighlight();
    }
    notifyListeners();
  }

  void showDocTool(bool show) {
    if (show != enableDocTool) {
      enableDocTool = show;
      notifyListeners();
    }
  }

  void beginSelect(Offset start, Offset end) {
    HL sel = HL()
      ..start = start
      ..end = start
      ..color = selectionColor;
    selection = sel;
    notifyListeners();
    if (enableHighlight) {
      addHighlight();
    }
  }

  void endSelect() {
    selection = HL();
    notifyListeners();
  }

  void updateSelection(Offset start, Offset end) {
    selection.start = start;
    selection.end = end;
    if (enableHighlight) {
      if (count() > 0) {
        doc?.hl[count() - 1].start = start;
        doc?.hl[count() - 1].end = end;
      }
    }
    notifyListeners();
  }

  void setColorByIndex(int index) {
    if (index >= colors.length) {
      return;
    }
    print(index);
    Color color = colorCombine(Colors.white, colors[index]);
    this._color = color;
    this._colorIndex = index;
    if (hasSelection()) {
      addHighlight();
    } else if (currentHighlight() != -1 && currentHighlight() < count()) {
      doc?.hl[currentHighlight()].color = color;
      doc?.hl[currentHighlight()].colorIndex = index;
      _highlightIndex = -1;
    }
    notifyListeners();
  }

  bool hasSelection() {
    return (selection.start.dx != -1 &&
        selection.start.dy != -1 &&
        selection.end.dx != -1 &&
        selection.end.dy != -1);
  }

  List<HL> hl() {
    List<HL> res = [...((doc?.hl ?? []).toList()), selection].toList();
    if (hasSelection()) {
      selection.color = enableHighlight ? currentColor() : selectionColor;
      res.add(selection);
    }

    if (_highlightIndex != -1 && _highlightIndex < count()) {
      res[_highlightIndex] = HL()
        ..start = res[_highlightIndex].start
        ..end = res[_highlightIndex].end
        ..color = colors[res[_highlightIndex].colorIndex]
        ..colorIndex = res[_highlightIndex].colorIndex;
    }

    return res;
  }
}
