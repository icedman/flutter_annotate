import 'dart:io';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' show Node;
import 'package:html/dom_parsing.dart' show TreeVisitor;

import 'touches.dart';
import 'annotate.dart';
import 'providers.dart';

const double paragraphSpacing = 24;

class AnnotateTool extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    EditorModel editor = Provider.of<EditorModel>(context);
    if (editor.currentHighlight() == -1) {
      return Container();
    }

    final target = editor.currentHighlight();
    return Positioned(
        left: 20,
        top: 20,
        child: Container(
          height: 30.0,
          width: 180,
          color: Colors.transparent,
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(const Radius.circular(8.0))
                  // borderRadius: BorderRadius.only(
                  //   topLeft: const Radius.circular(40.0),
                  //   topRight: const Radius.circular(40.0),
                  // )
                  ),
              child: Center(
                child: RichText(text: TextSpan(children: [
                  TextSpan(text: ' ${editor.currentHighlight()} '),
                  TextSpan(text: ' red ',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          editor.recolor(target, Colors.red);
                          }
                    ),
                  TextSpan(text: ' blue ',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          editor.recolor(target, Colors.blue);
                          }
                    ),
                  TextSpan(text: ' yellow ',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          editor.recolor(target, Colors.yellow);
                          }
                    ),
                  TextSpan(text: ' delete ',
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          editor.deleteHighlight(target);
                          }
                    )
                ]
                )),
              )),
        ));
  }
}

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

  int findHighlight(Offset pos) {
    EditorModel editor = Provider.of<EditorModel>(context, listen: false);
    int l = editor.hl.length;
    int idx = -1;
    for (int i = l-1; i > - 1; i--) {
      var hl = editor.hl[i];
      double start = hl.start.dx;
      double start_offset = hl.start.dy;
      double end = hl.end.dx;
      double end_offset = hl.end.dy;
      bool highlight = false;
      if (pos.dx >= start && pos.dx <= end) {
        highlight = true;
      }

      if (highlight) {
        if (pos.dx == start && pos.dy < start_offset) {
          highlight = false;
        }
      }
      if (highlight) {
        if (pos.dx == end && pos.dy > end_offset) {
          highlight = false;
        }
      }

      if (highlight) {
        idx = i;
        break;
      }
    }

    print('hl:${idx}');
    return idx;
    return -1;
  }

  Offset _screenToCursor(List<RenderParagraph> pars, Offset pos) {
    RenderObject? obj = context.findRenderObject();
    if (this.doc == null || obj == null) return Offset(-1, -1);
    RenderBox? box = obj as RenderBox;
    // Offset thisPos = obj.localToGlobal(Offset(0, 0));

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

      RenderBox? pbox = p as RenderBox;
      Offset pPos = pbox.localToGlobal(Offset(0, 0));
      // print(pbox.localToGlobal(Offset(0,0)));

      TextSpan _t = p.text as TextSpan;

      Rect bounds = Offset(0, 0) & p.size;
      Offset offsetForCaret =
          p.getOffsetForCaret(TextPosition(offset: 0), bounds);

      Offset spanPos = p.localToGlobal(offsetForCaret);
      if (pos.dx >= pPos.dx &&
          pos.dx < pPos.dx + bounds.width &&
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
        if (!(span is TextSpanWrapper)) return;
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
      // print(offset);
      // print((elm as Node).text);
      EditorModel editor = Provider.of<EditorModel>(context, listen: false);
      editor.beginHighlight(findHighlight(offset));
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

        EditorModel editor = Provider.of<EditorModel>(context, listen: false);

        HL sel = HL()
          ..start = start
          ..end = start
          ..color = editor.color;

        editor.hl.add(sel);
        editor.beginHighlight(editor.hl.length-1);
        editor.notifyListeners();
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

    EditorModel editor = Provider.of<EditorModel>(context, listen: false);

    if (this.doc != null) {
      int? idx = editor.hl.length;
      if (idx != null) {
        editor.hl[idx - 1].start = p1;
        editor.hl[idx - 1].end = p2;
        editor.notifyListeners();
        // setState(() {
        //   pulse = !pulse;
        // });
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

  Widget buildTable(BuildContext context, int start, int end) {
    EditorModel editor = Provider.of<EditorModel>(context);
    List<Widget> rows = <Widget>[];
    List<Widget> cells = <Widget>[];
    List<HtmlSpan> spans = <HtmlSpan>[];
    if (this.doc != null) {
      for (int i = start; i < end; i++) {
        var elm = this.doc?.elms[i];
        if (elm is Marker) {
          Marker m = elm as Marker;
          if (m.elm == 'tr') {
            cells = <Widget>[];
          }
          if (m.elm == 'td') {
            spans = <HtmlSpan>[];
          }
          if (m.elm == '/td') {
            cells.add(Expanded(
                flex: 1,
                child: RichText(
                    text: TextSpan(children: injectHL(this.doc, editor.hl, spans)))));
          }
          if (m.elm == '/tr') {
            rows.add(Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(children: cells)));
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
            sup: this.doc?.isSup(i) ?? true,
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

  Widget buildTextList(BuildContext context) {
    int? count = 0;

    List<Widget> children = <Widget>[];
    if (this.doc != null) {
      count = this.doc?.breaks.length;
      if (count != null) {
        count += 2;
      }
    }

    EditorModel editor = Provider.of<EditorModel>(context);
    print(editor.currentHighlight());

    return ListView.builder(
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
                center = this.doc?.isCenter(i, end: end + 20) ?? true;
              }
              if (!table) {
                table = this.doc?.isTable(i, end: end) ?? true;
                if (table) {
                  return buildTable(context, start, end);
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
                    sup: this.doc?.isSup(i) ?? true,
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
                    left: padLeftRight, right: padLeftRight, bottom: 24),
                child: ClipRect(
                    child: RichText(
                        textAlign:
                            center ? TextAlign.center : TextAlign.justify,
                        text: TextSpan(children: injectHL(this.doc, editor.hl, spans)))));
          }
          return Container();
        });
  }

  @override
  Widget build(BuildContext context) {
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
                child: Stack(
                    children: [buildTextList(context), AnnotateTool()]))));
  }
}
