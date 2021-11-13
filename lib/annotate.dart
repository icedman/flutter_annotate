import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' show Node;
import 'package:html/dom_parsing.dart' show TreeVisitor;

const String defaultFamily = 'FiraCode';
const double defaultSize = 20;

List<InlineSpan> injectHL(AnnotateDoc? doc, List<HtmlSpan> spans) {
  List<InlineSpan> spns = <InlineSpan>[];
  List<HtmlSpan> hld = <HtmlSpan>[];
  int start = -1;
  int end = 0;
  spans.forEach((s) {
    var elm = doc?.elms[s.index];
    if (start == -1) start = s.index;
    end = s.index;
    String text = '';
    if (elm is Node) {
      text = '${(elm as Node).text}';
    }
    s.text = text;

    for (int i = 0; i < text.length; i++) {
      HtmlSpan ss = HtmlSpan(
        index: s.index,
        pos: i,
        length: 1,
        bold: s.bold,
        italic: s.italic,
        underline: s.underline,
        sup: s.sup,
      );
      ss.text = text.substring(ss.pos, ss.pos + ss.length);
      ss.background = Color.fromRGBO(0, 0, 0, 0);

      if (doc != null) {
        doc.hl.forEach((hl) {
          bool highlight = false;
          if (ss.index >= hl.start.dx && ss.index <= hl.end.dx) {
            highlight = true;
          }
          if (highlight) {
            if (ss.index == hl.start.dx && ss.pos < hl.start.dy) {
              highlight = false;
            }
          }
          if (highlight) {
            if (ss.index == hl.end.dx && ss.pos > hl.end.dy) {
              highlight = false;
            }
          }
          if (highlight) {
            ss.background = hl.color;
          }
        });
      }

      if (hld.length > 0) {
        if (hld[hld.length - 1].isEqual(ss)) {
          hld[hld.length - 1].length++;
          hld[hld.length - 1].text = text.substring(hld[hld.length - 1].pos,
              hld[hld.length - 1].pos + hld[hld.length - 1].length);
          continue;
        }
      }

      hld.add(ss);
    }
  });

    spns.add(TextSpanWrapper(
        text: '${start}-${end}', style: TextStyle(color: Colors.red)));

  hld.forEach((s) {
    spns.add(s.toTextSpan(doc, s.text));
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
  HL({
    Offset this.start = const Offset(0,0),
    Offset this.end = const Offset(0,0),
    Color this.color = Colors.red
  });

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
    bool this.sup = false,
    double this.fontSize = defaultSize,
    Color this.color = Colors.black,
    Color this.background = Colors.white,
  });

  int index = 0;
  int pos = 0;
  int length = 0;

  bool bold = false;
  bool italic = false;
  bool underline = false;
  bool sup = false;
  double fontSize = 0;
  Color color = Colors.black;
  Color background = Colors.white;
  String text = '';

  bool isEqual(HtmlSpan s) {
    return index == s.index &&
        bold == s.bold &&
        italic == s.italic &&
        underline == s.underline &&
        sup == s.sup &&
        fontSize == s.fontSize &&
        color == s.color &&
        background == s.background;
  }

  TextSpanWrapper toTextSpan(AnnotateDoc? doc, String text) {
    if (doc == null) {
      return TextSpanWrapper(text: text);
    }

    // Paint? paint;
    // if (background.opacity > 0) {
    //   paint = Paint()
    //     ..color = background
    //     ..style = PaintingStyle.stroke
    //     ..strokeWidth = 2;
    // }

    TextStyle style = TextStyle(
      color: Colors.black,
      fontFamily: defaultFamily,
      fontSize: sup ? fontSize * 0.75 : fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: underline ? TextDecoration.underline : TextDecoration.none,
      backgroundColor: background,
      // background: paint
    );
    Offset ext = getExtents(style);

    int p = pos;
    int l = length;
    if (p + l > text.length) {
      l = text.length - p;
    }
    return TextSpanWrapper(
        text: text,
        mouseCursor: sup ? MaterialStateMouseCursor.clickable : null,
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

class Marker {
  Marker(String this.elm, Node? this.node, { int this.start: 0, int this.end: 0});
  String elm = '';
  Node? node;
  int start = 0;
  int end = 0;
}

class AnnotateDoc {
  AnnotateDoc(var this.document);

  var document;
  var elms = <Object>[];
  var breaks = <int>[];
  var hl = <HL>[];

  bool isWithinMarkup(List<String> markers, int index, {int end = 0})
  {
    for (int i = index; i > 0; i--) {
      var elm = elms[i];
      if (elm is Marker) {
        Marker m = elm as Marker;
        for(int j = 0; j<markers.length; j++) {
          if (m.elm == markers[j]) {
            if (m.end > index) {
              return true;
            }
          }
        }
      }
      if (index - i > 20) return false;
    }
    return false;
  }

  bool isBold(int index, {int end = 0}) {
    return isWithinMarkup(['b','strong','h1','h2','h3','h4','h5','h6'], index, end:end);
  }

  bool isTable(int index, {int end = 0}) {
    return isWithinMarkup(['table'], index, end:end);
  }

  bool isItalic(int index, {int end = 0}) {
    return isWithinMarkup(['i', 'em'], index, end:end);
  }

  bool isUnderline(int index, {int end = 0}) {
    return isWithinMarkup(['u'], index, end:end);
  }

  bool isSup(int index, {int end = 0}) {
    return isWithinMarkup(['sup'], index, end:end);
  }

  bool isCenter(int index, {int end = 0})
  {
    return isWithinMarkup(['center', 'div:center'], index, end: end);
  }

  bool isBlock(int index, {int end = 0})
  {
    return isWithinMarkup(['blockquote'], index, end: end);
  }
}

class AnnotateTreeVisitor extends TreeVisitor {
  var doc;
  List<int> withinTable = <int>[];

  @override
  void visitText(n) {
    doc.elms.add(n);
  }

  @override
  void visitElement(n) {
    bool style = false;
    Marker startMarker = Marker('', n);
    if (isTrackedMarkup(n)) {
      style = true;
      startMarker = Marker('${n.localName}', n);
      startMarker.start = doc.elms.length;
      doc.elms.add(startMarker);
    }
    if (n.localName == 'div') {
      if (n.attributes['align'] != null) {
        var align = '${n.attributes['align']}'.toLowerCase();
        startMarker = Marker('${n.localName}:${align}', n);
        startMarker.start = doc.elms.length;
        doc.elms.add(startMarker);
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
      Marker endMarker = Marker('/${n.localName}', n);
      startMarker.end = doc.elms.length;
      doc.elms.add(endMarker);
    }
    if (withinTable.length == 0 && isBreakWithin(n)) {
      doc.breaks.add(doc.elms.length);
    }

    if (isTable) {
      withinTable.removeAt(0);
    }
  }

  bool isTrackedMarkup(n) {
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
      case 'sup':
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
}
