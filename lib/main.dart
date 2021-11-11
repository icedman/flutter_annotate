import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' show Node;
import 'package:html/dom_parsing.dart' show TreeVisitor;

import 'touches.dart';

class HL {
  Offset start = Offset(0,0);
  Offset end = Offset(0,0);
  Color color = Colors.red;
}

Offset getExtents(style) {
    //final style = TextStyle(fontFamily: fontFamily, fontSize: fontSize);
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: "?", style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    double fw = textPainter.size.width;
    double fh = textPainter.size.height;
    return Offset(fw, fh);
}

class TextSpanWrapper extends TextSpan {
  int index = 0;
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

void main() async {
  File file = File('./article.html');

  String contents = await file.readAsString();
  var document = parse(contents);
  var doc = MyDoc();
  var tree = MyVisitor();
  tree.doc = doc;
  tree.visit(document);

  //int i=0;
  //doc.elms.forEach((elm) {
  //  if (i>220) return;
  //  print('${i++} ${elm.toString()}');
  //  });
  //print(doc.breaks);

  runApp(MyApp(doc: doc));
}

class MyApp extends StatefulWidget {
  MyApp({Key? this.key, MyDoc? this.doc}) : super();

  Key? key;
  MyDoc? doc;

    @override
  _MyApp createState() => _MyApp(doc: this.doc);
}

class _MyApp extends State<MyApp> {
  _MyApp({Key? key, MyDoc? this.doc}) : super();

  MyDoc? doc;
  double fontSize = 24;

  bool _isBold(int index, { int end = 0 })
  { 
    int? l = this.doc?.elms.length;
    if (l != null) {
      for(int i=index;i<l;i++) {
        if (end != 0 && i > end) break;
        var elm = this.doc?.elms[i];
        if (elm is String) {
          if (elm == '/b' || elm == '/strong' ||
              elm == '/h1' || elm == '/h2' || elm == '/h3' || elm == '/h4') {
            return true;
          }
          if (elm == 'b' || elm == 'strong' ||
              elm == 'h1' || elm == 'h2' || elm == 'h3' || elm == 'h4') {
            return false;
          }
        }
      }
    }
    return false;
  }

  bool _isTable(int index, { int end = 0 })
  { 
    int? l = this.doc?.elms.length;
    if (l != null) {
      for(int i=index;i<l;i++) {
        if (end != 0 && i > end) break;
        var elm = this.doc?.elms[i];
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

  bool _isItalic(int index, { int end = 0 })
  {
    int? l = this.doc?.elms.length;
    if (l != null) {
      for(int i=index;i<l;i++) {
        if (end != 0 && i > end) break;
        var elm = this.doc?.elms[i];
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

  bool _isUnderline(int index, { int end = 0 })
  {
    int? l = this.doc?.elms.length;
    if (l != null) {
      for(int i=index;i<l;i++) {
        if (end != 0 && i > end) break;
        var elm = this.doc?.elms[i];
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

  bool _isCenter(int index, { int end = 0 })
  {
    bool checkDiv = false;
    int? l = this.doc?.elms.length;
    if (l != null) {
      for(int i=index;i<l;i++) {
        if (end != 0 && i > end) break;
        var elm = this.doc?.elms[i];
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

      for(int i=index;i>0;i--) {
        var elm = this.doc?.elms[i];
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

  bool _isBlock(int index, { int end = 0 })
  {
    int? l = this.doc?.elms.length;
    if (l != null) {
      for(int i=index;i<l;i++) {
        if (end != 0 && i > end) break;
        var elm = this.doc?.elms[i];
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

  void _findRenderParagraphs(RenderObject? obj, List<RenderParagraph> res) {
    if (obj is RenderParagraph) {
      res.add(obj);
    }
    obj?.visitChildren((child) {
      _findRenderParagraphs(child, res);
    });
  }

  Offset _screenToCursor(List<RenderParagraph> pars, Offset pos) {
    // print('------------');
    // print(pos);

    TextSpanWrapper? target;
    RenderParagraph? targetPar;
    Offset targetSpanPos = Offset(0, 0);
    int targetOffset = 0;

    const double adjustX = 1;
    const double adjustY = 1;

    // find paragraph
    for (final p in pars) {
      if (target != null) {
        break;
      }

      TextSpan _t = p.text as TextSpan;

      Rect bounds = Offset(0, 0) & p.size;
      Offset offsetForCaret =
          p.getOffsetForCaret(TextPosition(offset: 0), bounds);

      Offset spanPos = p.localToGlobal(offsetForCaret);

      if (pos.dx >= spanPos.dx &&
          pos.dx < spanPos.dx + bounds.width &&
          pos.dy + adjustY >= spanPos.dy - 1 &&
          pos.dy + adjustY < spanPos.dy + 2 + bounds.height) {
        targetPar = p;
        break;
      }
    }

    // find span
    if (targetPar != null) {
      Rect bounds = Offset(0, 0) & targetPar.size;

      TextSpan? _t = targetPar.text as TextSpan;

      List<InlineSpan>? _c = _t.children;
      int textOffset = 0;
      bool found = false;
      int line = 0;
      int position = 0;
      _c?.forEach((span) {
        if (found) return;
        line = (span as TextSpanWrapper).index;
        String? _s = (span as TextSpan).text;
        if (_s == null) return;

        for (int i = 0; i < _s.length; i++) {
          Offset? offsetForCaret = targetPar?.getOffsetForCaret(
              TextPosition(offset: textOffset + i), bounds);
          if (offsetForCaret == null) break;
          Offset? spanPos = targetPar?.localToGlobal(offsetForCaret);
          if (spanPos == null) break;

          if (pos.dx + adjustX >= spanPos.dx &&
              pos.dx + adjustX < spanPos.dx + (span as TextSpanWrapper).fw &&
              pos.dy + adjustY >= spanPos.dy - 1 &&
              pos.dy + adjustY <
                  spanPos.dy + 2 + (span as TextSpanWrapper).fh) {
            // print(_s);
            found = true;
            position = textOffset + i;
            line = (span as TextSpanWrapper).index;
            break;
          }
        }

        textOffset += _s.length;
        if (!found) {
          position = textOffset;
        }
      });

      return Offset(line.toDouble(), position.toDouble());
    }

    return Offset(-1, -1);
  }

  void _onTapDown(Widget child, Offset pos) {
    RenderObject? obj = context.findRenderObject();
    if (this.doc == null || obj == null) return;

    List<RenderParagraph> pars = <RenderParagraph>[];
    _findRenderParagraphs(obj, pars);

    Offset offset = _screenToCursor(pars, pos);
    if (offset.dx >= 0) {
      var elm = this.doc?.elms[offset.dx.toInt()];
      print(offset);
      //print(elm);
    }
  }

  List<InlineSpan> injectHL(List<InlineSpan> spans)
  {
    List<InlineSpan> spns = <InlineSpan>[];
    spans.forEach((s) {
      TextSpanWrapper tsw = s as TextSpanWrapper;
      TextStyle? style = s.style;
      String? text = (s as TextSpan).text;

      if (text == null || style == null) {
        spns.add(s);
        return;
      }

      for(int i=0; i<text.length; i++) {
        if (this.doc != null) {
          this.doc?.hl.forEach((hl) {

            if (tsw.index >= hl.start.dx && tsw.index < hl.end.dx) {
              print('HL! ${tsw.index} ${hl.start} ${hl.end} ${text} ${hl.color}');
            }

          });
        }
      }

      spns.add(s);
      });
    return spns;
  }

  Widget buildTable(int start, int end) {
    List<Widget> rows = <Widget>[];
    List<Widget> cells = <Widget>[];
    List<InlineSpan> spans = <InlineSpan>[];
    if (this.doc != null) {
      for(int i=start; i<end; i++) {
        var elm = this.doc?.elms[i];
        if (elm is String) {
          if (elm == 'tr') {
            cells = <Widget>[];
          }
          if (elm == 'td') {
            spans = <InlineSpan>[];
          }
          if (elm == '/td') {
            cells.add(Expanded(flex:1, child: RichText(text:TextSpan(children: injectHL(spans)))));
          }
          if (elm == '/tr') {
            rows.add(Row(children:cells)); 
          }
        }
        if (elm is Node) {
          TextStyle style = TextStyle(
            color: Colors.black,
            fontFamily: 'Times',
            fontSize: fontSize,
            fontWeight: _isBold(i)
                ? FontWeight.bold
                : FontWeight.normal,
            fontStyle: _isItalic(i)
                ? FontStyle.italic
                : FontStyle.normal,
            decoration: _isUnderline(i)
                ? TextDecoration.underline
                : TextDecoration.none);
          Offset ext = getExtents(style);
          spans.add(TextSpanWrapper(text: '${elm.text}', style: style, index: i, fw: ext.dx, fh: ext.dy));
        }
      }
    }

    double padLeftRight = 80;
    return Padding(padding: EdgeInsets.only(left: padLeftRight, right: padLeftRight, bottom: 24),
        child: Column(children: rows));
  }

  @override
  Widget build(BuildContext context) {
    int? count = 0;

    List<Widget> children = <Widget>[];
    if (this.doc != null) {
      count = this.doc?.breaks.length;
      if (count != null) {
        count += 2;
      }
    }

    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
            body: TouchInputListener(
              onTapDown: _onTapDown,
              child: ListView.builder(
                itemCount: count,
                itemBuilder: (context, index) {

                  bool block = false;
                  bool center = false;
                  bool table = false;

                  if (this.doc != null) {
                    int? ii = index;
                    int? sz = this.doc?.breaks.length;
                    if (ii != null && sz != null && ii >= sz) {
                      return Container(height: 200);
                    }

                    var br = this.doc?.breaks[index];
                    int start = 0;
                    int end = 0;
                    if (br != null) {
                      end = br;
                    }
                    if (index > 0) {
                      br = doc?.breaks[index - 1];
                      if (br != null) {
                        start = br;
                      }
                    }
                    if (start < 0 || start == end) {
                      return Container();
                    }

                    List<InlineSpan> spans = <InlineSpan>[];
                    
                    // remove
                    List<String> styles = <String>[];

                    String text = '';
                    for (int i = start; i < end; i++) {
                      if (!block) {
                        block = _isBlock(i, end: end + 20);
                      }
                      if (!center) {
                        center = _isCenter(i, end: end + 20);
                      }
                      if (!table) {
                        table = _isTable(i, end: end);                    
                        if (table) {
                          return buildTable(start, end);
                        }
                      }
                      var elm = doc?.elms[i];
                      if (elm != null) {

                        if (elm is Node) {
                          TextStyle style = TextStyle(
                            color: Colors.black,
                            fontFamily: 'Times',
                            fontSize: fontSize,
                            fontWeight: _isBold(i)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontStyle: _isItalic(i)
                                ? FontStyle.italic
                                : FontStyle.normal,
                            decoration: _isUnderline(i)
                                ? TextDecoration.underline
                                : TextDecoration.none);
                          Offset ext = getExtents(style);
                          spans.add(
                              TextSpanWrapper(text: '${elm.text} ', style: style, index: i, fw: ext.dx, fh: ext.dy));
                        }
                      }
                    }

                    double padLeftRight = 28;
                    if (block) {
                      padLeftRight *= 3;
                    }

                    return Padding(
                        padding: EdgeInsets.only(left: padLeftRight, right: padLeftRight, bottom: 24),
                        child: RichText(
                          textAlign: center ? TextAlign.center : TextAlign.justify,
                          text: TextSpan(children: injectHL(spans)))
                        );
                  }
                  return Container();
                }))));
  }
}
