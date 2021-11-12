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
import 'annotate.dart';

class Editor extends StatefulWidget {
  Editor({Key? this.key, AnnotateDoc? this.doc}) : super();

  Key? key;
  AnnotateDoc? doc;

  @override
  _Editor createState() => _Editor(doc: this.doc);
}

class _Editor extends State<Editor> {
  _Editor({Key? key, AnnotateDoc? this.doc}) : super();

  AnnotateDoc? doc;
  double fontSize = 24;
  bool pulse = false;

  void _findRenderParagraphs(RenderObject? obj, List<RenderParagraph> res) {
    if (obj is RenderParagraph) {
      res.add(obj);
    }
    obj?.visitChildren((child) {
      _findRenderParagraphs(child, res);
    });
  }

  Offset _screenToCursor(List<RenderParagraph> pars, Offset pos) {
    RenderObject? obj = context.findRenderObject();
    if (this.doc == null || obj == null) return Offset(-1, -1);
    RenderBox? box = obj as RenderBox;
    Offset thisPos = obj.localToGlobal(Offset(0, 0));

    // print('------------');
    // print(pos);

    TextSpanWrapper? target;
    RenderParagraph? targetPar;
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
      if (pos.dx >= thisPos.dx &&
          pos.dx < thisPos.dx + bounds.width &&
          pos.dy + adjustY >= spanPos.dy - 20 &&
          pos.dy + adjustY < spanPos.dy + 20 + bounds.height) {
        targetPar = p;

        // print('${pos} ${spanPos} ${bounds}');

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
        String? _s = (span as TextSpan).text;
        if (_s == null) return;

        if (line == 0) line = (span as TextSpanWrapper).index;

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
            found = true;
            position = (span as TextSpanWrapper).pos + i; // textOffset + i;
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
    if (offset.dx > 0) {
      var elm = this.doc?.elms[offset.dx.toInt()];
      print(offset);
    }
  }

  Offset start = Offset(0, 0);
  Offset end = Offset(0, 0);
  void _onDragStart(Widget child, Offset pos) {
    RenderObject? obj = context.findRenderObject();
    if (this.doc == null || obj == null) return;

    List<RenderParagraph> pars = <RenderParagraph>[];
    _findRenderParagraphs(obj, pars);

    Offset offset = _screenToCursor(pars, pos);
    if (offset.dx > 0) {
      var elm = this.doc?.elms[offset.dx.toInt()];
      if (offset.dx != -1) {
        start = offset;

        HL sel = HL()
          ..start = start
          ..end = start
          ..color = Colors.yellow;
        this.doc?.hl.add(sel);
      }
    }
  }

  void _updateLastSelection(Offset p1, Offset p2) {
    if (p1.dx > p2.dx || (p1.dx == p2.dx && p1.dy > p2.dy)) {
      Offset p3 = p1;
      p1 = p2;
      p2 = p3;
    }

    // print('${p1} ${p2}');

    if (this.doc != null) {
      int? idx = this.doc?.hl.length;
      if (idx != null) {
        this.doc?.hl[idx - 1].start = p1;
        this.doc?.hl[idx - 1].end = p2;
        setState(() {
          pulse = !pulse;
        });
      }
    }
  }

  void _onDragUpdate(Widget child, Offset pos) {
    RenderObject? obj = context.findRenderObject();
    if (this.doc == null || obj == null) return;

    List<RenderParagraph> pars = <RenderParagraph>[];
    _findRenderParagraphs(obj, pars);

    Offset offset = _screenToCursor(pars, pos);
    if (offset.dx > 0) {
      var elm = this.doc?.elms[offset.dx.toInt()];
      if (offset.dx != -1) {
        end = offset;
        _updateLastSelection(start, end);
      }
    }
  }

  void _onDragEnd(Widget child, Offset pos) {
    _updateLastSelection(start, end);
  }

  Widget buildTable(int start, int end) {
    List<Widget> rows = <Widget>[];
    List<Widget> cells = <Widget>[];
    List<HtmlSpan> spans = <HtmlSpan>[];
    if (this.doc != null) {
      for (int i = start; i < end; i++) {
        var elm = this.doc?.elms[i];
        if (elm is String) {
          if (elm == 'tr') {
            cells = <Widget>[];
          }
          if (elm == 'td') {
            spans = <HtmlSpan>[];
          }
          if (elm == '/td') {
            cells.add(Expanded(
                flex: 1,
                child: RichText(
                    text: TextSpan(children: injectHL(this.doc, spans)))));
          }
          if (elm == '/tr') {
            rows.add(Row(children: cells));
          }
        }
        if (elm is Node) {
          HtmlSpan span = HtmlSpan(
            index: i,
            pos: 0,
            length: 0,
            bold: this.doc?.isBold(i) ?? true,
            italic: this.doc?.isItalic(i) ?? true,
            underline: this.doc?.isUnderline(i) ?? true,
          );
          spans.add(span);
        }
      }
    }

    double padLeftRight = 80;
    return Padding(
        padding: EdgeInsets.only(
            left: padLeftRight, right: padLeftRight, bottom: 24),
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
                onDragStart: _onDragStart,
                onDragUpdate: _onDragUpdate,
                onDragEnd: _onDragEnd,
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

                        List<HtmlSpan> spans = <HtmlSpan>[];

                        // remove
                        List<String> styles = <String>[];

                        String text = '';
                        for (int i = start; i < end; i++) {
                          if (!block) {
                            block = this.doc?.isBlock(i, end: end + 20) ?? true;
                          }
                          if (!center) {
                            center =
                                this.doc?.isCenter(i, end: end + 20) ?? true;
                          }
                          if (!table) {
                            table = this.doc?.isTable(i, end: end) ?? true;
                            if (table) {
                              return buildTable(start, end);
                            }
                          }

                          var elm = doc?.elms[i];
                          if (elm != null) {
                            if (elm is Node) {
                              HtmlSpan span = HtmlSpan(
                                index: i,
                                pos: 0,
                                length: 0,
                                bold: this.doc?.isBold(i) ?? true,
                                italic: this.doc?.isItalic(i) ?? true,
                                underline: this.doc?.isUnderline(i) ?? true,
                              );
                              spans.add(span);
                            }
                          }
                        }

                        double padLeftRight = 28;
                        if (block) {
                          padLeftRight *= 3;
                        }

                        return Padding(
                            padding: EdgeInsets.only(
                                left: padLeftRight,
                                right: padLeftRight,
                                bottom: 24),
                            child: RichText(
                                textAlign: center
                                    ? TextAlign.center
                                    : TextAlign.justify,
                                text: TextSpan(
                                    children: injectHL(this.doc, spans))));
                      }
                      return Container();
                    }))));
  }
}
