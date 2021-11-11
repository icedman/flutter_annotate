import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' show Node;
import 'package:html/dom_parsing.dart' show TreeVisitor;

List<InlineSpan> injectHL(MyDoc? doc, List<InlineSpan> spans) {
    List<InlineSpan> spns = <InlineSpan>[];
    spans.forEach((s) {
      TextSpanWrapper tsw = s as TextSpanWrapper;
      TextStyle? style = s.style;
      String? text = (s as TextSpan).text;

      if (text == null || style == null) {
        spns.add(s);
        return;
      }

      for (int i = 0; i < text.length; i++) {
        if (doc != null) {
          doc.hl.forEach((hl) {
            if (tsw.index >= hl.start.dx && tsw.index < hl.end.dx) {
              //print(
              //    'HL! ${tsw.index} ${hl.start} ${hl.end} ${text} ${hl.color}');
            }
          });
        }
      }

      spns.add(s);
    });
    return spns;
  }

  List<InlineSpan> _injectHL(MyDoc? doc, List<HtmlSpan> spans) {
    List<InlineSpan> spns = <InlineSpan>[];
    spans.forEach((s) {

      //for (int i = 0; i < text.length; i++) {
      //  if (this.doc != null) {
      //    this.doc?.hl.forEach((hl) {
      //      if (tsw.index >= hl.start.dx && tsw.index < hl.end.dx) {
      //        print(
      //            'HL! ${tsw.index} ${hl.start} ${hl.end} ${text} ${hl.color}');
      //      }
      //    });
      //  }
      //}

      spns.add(s.toTextSpan(doc, 'xx'));
    });
    return spns;
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

class HL {
  Offset start = Offset(0, 0);
  Offset end = Offset(0, 0);
  Color color = Colors.red;
}

class HtmlSpan {
  HtmlSpan({
      int this.index = 0,
      int this.pos = 0,
      int this.length = 0,
      bool this.bold = false,
      bool this.italic = false,
      bool this.underline = false,
      double this.fontSize = 12,
      Color this.color = Colors.black,
      Color this.background = Colors.white,  
    });

  int index = 0;
  int pos = 0;
  int length = 0;

  bool bold = false;
  bool italic = false;
  bool underline = false;
  double fontSize = 0;
  Color color = Colors.black;
  Color background = Colors.white;

  bool isEqual(HtmlSpan s) {
    return index == s.index &&
        bold == s.bold &&
        italic == s.italic &&
        underline == s.underline &&
        fontSize == s.fontSize &&
        color == s.color &&
        background == s.background;
  }

  TextSpanWrapper toTextSpan(MyDoc? doc, String text) {
    if (doc == null) {
      return TextSpanWrapper(text: text);
    }
    TextStyle style = TextStyle(
      color: Colors.black,
      fontFamily: 'Times',
      fontSize: fontSize,
      //fontWeight: doc?.isBold(i)
      //    ? FontWeight.bold
      //    : FontWeight.normal,
      //fontStyle: doc?.isItalic(i)
      //    ? FontStyle.italic
      //    : FontStyle.normal,
      //decoration: doc?.isUnderline(i)
      //    ? TextDecoration.underline
      //    : TextDecoration.none
    );
    Offset ext = getExtents(style);
    return TextSpanWrapper(
        text: text,
        style: style,
        index: index,
        pos: pos,
        length: length,
        fw: ext.dx,
        fh: ext.dy);
  }
}

class TextSpanWrapper extends TextSpan {
  int index = 0;
  int pos = 0;
  int length = 0;
  double fw = 12;
  double fh = 24;

  TextSpanWrapper(
      {String? text,
      List<InlineSpan>? children,
      TextStyle? style,
      GestureRecognizer? recognizer,
      MouseCursor? mouseCursor,
      PointerEnterEventListener? onEnter,
      PointerExitEventListener? onExit,
      String? semanticsLabel,
      Locale? locale,
      bool? spellOut,
      int this.index = 0,
      int this.pos = 0,
      int this.length = 0,
      double this.fw = 12,
      double this.fh = 24})
      : super(
            text: text,
            children: children,
            style: style,
            recognizer: recognizer,
            mouseCursor: mouseCursor,
            onEnter: onEnter,
            semanticsLabel: semanticsLabel,
            locale: locale,
            spellOut: spellOut);
}

bool isStyle(n) {
  switch (n.localName) {
    case 'b':
    case 'u':
    case 'em':
    case 'i':
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
    case 'strong':
    case 'center':
    case 'blockquote':
    case 'table':
    case 'tr':
    case 'td':
      return true;
  }
  return false;
}

bool isBreak(n) {
  switch (n.localName) {
    case 'br':
    case 'table':
      return true;
  }
  return false;
}

bool isBreakWithin(n) {
  switch (n.localName) {
    case 'h1':
    case 'h2':
    case 'h3':
    case 'h4':
    case 'h5':
    case 'h6':
    case 'center':
    case 'blockquote':
      return true;
  }
  return false;
}

class MyDoc {
  var document;
  var elms = <Object>[];
  var breaks = <int>[];
  var hl = <HL>[];

  MyDoc() {
    HL _hl = HL();
    _hl.start = Offset(24, 44);
    _hl.end = Offset(50, 509);
    hl.add(_hl);
  }

  bool isBold(int index, {int end = 0}) {
    int l = elms.length;
    if (l != null) {
      for (int i = index; i < l; i++) {
        if (end != 0 && i > end) break;
        var elm = elms[i];
        if (elm is String) {
          if (elm == '/b' ||
              elm == '/strong' ||
              elm == '/h1' ||
              elm == '/h2' ||
              elm == '/h3' ||
              elm == '/h4') {
            return true;
          }
          if (elm == 'b' ||
              elm == 'strong' ||
              elm == 'h1' ||
              elm == 'h2' ||
              elm == 'h3' ||
              elm == 'h4') {
            return false;
          }
        }
      }
    }
    return false;
  }

  bool isTable(int index, {int end = 0}) {
    int l = elms.length;
    if (l != null) {
      for (int i = index; i < l; i++) {
        if (end != 0 && i > end) break;
        var elm = elms[i];
        if (elm is String) {
          if (elm == '/table') {
            return true;
          }
          if (elm == 'table') {
            return false;
          }
        }
      }
    }
    return false;
  }

  bool isItalic(int index, {int end = 0}) {
    int l = elms.length;
    if (l != null) {
      for (int i = index; i < l; i++) {
        if (end != 0 && i > end) break;
        var elm = elms[i];
        if (elm is String) {
          if (elm == '/i' || elm == '/em') {
            return true;
          }
          if (elm == 'i' || elm == 'em') {
            return false;
          }
        }
      }
    }
    return false;
  }

  bool isUnderline(int index, {int end = 0}) {
    int l = elms.length;
    if (l != null) {
      for (int i = index; i < l; i++) {
        if (end != 0 && i > end) break;
        var elm = elms[i];
        if (elm is String) {
          if (elm == '/u') {
            return true;
          }
          if (elm == 'u') {
            return false;
          }
        }
      }
    }
    return false;
  }

  bool isCenter(int index, {int end = 0}) {
    bool checkDiv = false;
    int l = elms.length;
    if (l != null) {
      for (int i = index; i < l; i++) {
        if (end != 0 && i > end) break;
        var elm = elms[i];
        if (elm is String) {
          if (elm == '/center') {
            return true;
          }
          if (elm == '/div') {
            checkDiv = true;
          }
          if (elm == 'center') {
            break;
          }
        }
      }

      if (!checkDiv) return false;

      for (int i = index; i > 0; i--) {
        var elm = elms[i];
        if (elm is String) {
          if (elm == 'div:center') {
            return true;
          }
          if (elm.startsWith('div')) return false;
        }
      }
    }
    return false;
  }

  bool isBlock(int index, {int end = 0}) {
    int l = elms.length;
    if (l != null) {
      for (int i = index; i < l; i++) {
        if (end != 0 && i > end) break;
        var elm = elms[i];
        if (elm is String) {
          if (elm == '/blockquote') {
            return true;
          }
          if (elm == 'blockquote') {
            return false;
          }
        }
      }
    }
    return false;
  }
}

class MyVisitor extends TreeVisitor {
  var doc;
  List<int> withinTable = <int>[];

  @override
  void visitText(n) {
    doc.elms.add(n);
  }

  @override
  void visitElement(n) {
    bool style = false;
    if (isStyle(n)) {
      style = true;
      doc.elms.add(n.localName);
    }
    if (n.localName == 'div') {
      if (n.attributes['align'] != null) {
        var align = '${n.attributes['align']}'.toLowerCase();
        //print('${n.localName}:${align}');
        doc.elms.add('${n.localName}:${align}');
        style = true;
      }
    }
    bool isTable = false;
    if (n.localName == 'table') {
      withinTable.add(1);
      isTable = true;
    }
    if (withinTable.length == 0 && isBreak(n)) {
      doc.breaks.add(doc.elms.length);
    }
    visitChildren(n);
    if (style) {
      doc.elms.add('/${n.localName}');
      //print('[/${n.localName}]');
    }
    if (withinTable.length == 0 && isBreakWithin(n)) {
      doc.breaks.add(doc.elms.length);
    }

    if (isTable) {
      withinTable.removeAt(0);
    }
  }
}
