import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';// show Node, Element;
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
        sel.index = int.parse(idx.group(0).toString()) - 1;
      }

      // print('${sel.elm} ${sel.index}');
      res.add(sel);
    });

    return res;
  }
  
  static Offset findPath(AnnotateDoc? doc, String path,{ int offset = 0 }) {
    Offset res = Offset(-1, -1);
    List<XSel> p = parsePath(path);
    if (doc == null) {
        return res;
    }

    var elm = doc.document;
    // var div = doc.document?.querySelector('div');
    // var block = div?.querySelector('blockquote');

    p.forEach((s) {
      elm = elm?.querySelector(s.elm);  
      var parent = elm?.parent;
      int idx = 0;
      for(int i=0;i<parent.children.length && idx <= s.index; i++) {
        var child = parent.children.elementAt(i);
        if (child.localName == s.elm) {
          elm = child;
          idx++;
        }
      }
    });

    // print(elm.text);

    // find the element
    for(int i=0; i<doc.elms.length; i++) {
      var delm = doc.elms[i];
      if (delm is Marker) continue;
      if ((delm as Node).parent == (elm as Node)) {
        res = Offset(i.toDouble(), 0);
        break;
      }
    }

    if (res.dx == -1) return res;

    // find the offset
    int  start = res.dx.toInt();
    for(int i=res.dx.toInt(); i<doc.elms.length && offset > 0; i++) {
      var delm = doc.elms[i];
      if (delm is Marker) continue;
      int l = (delm as Node).text?.length ?? 0;
      res = Offset(i.toDouble(), offset.toDouble());
      offset -= l;
    }

    print(res);

    return res;
  }
}
  