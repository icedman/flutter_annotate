import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' show Node;
import 'package:html/dom_parsing.dart' show TreeVisitor;

import 'annotate.dart';

class XSel {
  String elm = '';
  int index = 0;
  int offset = 0;
}

class XPath {
  static List<XSel> parsePath(String path) {
    List<XSel> res = <XSel>[];

    RegExp regExp = new RegExp(
      r"\/([a-z\[\]0-9]*)",
      caseSensitive: false,
      multiLine: false,
    );
    RegExp regExpElm = new RegExp(
      r"[a-z]*",
      caseSensitive: false,
      multiLine: false,
    );
    RegExp regExpIndex = new RegExp(
      r"[a-z]*[0-9]*",
      caseSensitive: false,
      multiLine: false,
    );

    var matches = regExp.allMatches(path);
    matches.forEach((m) {
      XSel sel = XSel();
      var g = m.groups([0, 1]);
      var matchesElm = regExpElm.allMatches(g[1] ?? '');
      var elm = matchesElm.first;
      sel.elm = elm.group(0) ?? '';

      var matchesIdx = regExpIndex.allMatches(g[1] ?? '');
      if (matchesIdx.length > 2) {
        var idx = matchesIdx.elementAt(2);
        sel.index = int.parse(idx.group(0).toString());
      }

      // print('${sel.elm} ${sel.index}');
      res.add(sel);
    });

    return res;
  }
  static int findPath(AnnotateDoc? doc, String path) {
    List<XSel> p = parsePath(path);
    if (doc == null) {
        return -1;
    }

    p.forEach((s) => print('${s.elm}[${s.index}]'));
    return -1;
  }
}
