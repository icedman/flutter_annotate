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

import 'keys.dart';
import 'touches.dart';
import 'tools.dart';
import 'annotate.dart';
import 'scrollto.dart';

import 'providers/search.dart';
import 'providers/lawyerly.dart';
import 'providers/editor.dart';
import 'providers/app.dart';

const double paragraphSpacing = 24;

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
  bool shifting = false;
  bool ctrling = false;
  bool pulse = false;
  int editorFirstLine = 0;
  int editorLastLine = 0;

  final _scroller = ScrollController();
  final ScrollTo scrollToController = ScrollTo();

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();

    focusNode = FocusNode();
    _scroller.addListener(_onScroll);
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  Widget documentHeader() {
    return Container(
        height: 58,
        child: AppBar(elevation: 0, actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more),
          )
        ]));
    // return Container(height: 30);
  }

  List<int> getVisibleLines() {
    RenderObject? obj = context.findRenderObject();
    if (this.doc == null || obj == null) return [-1, -1];
    RenderBox? box = obj as RenderBox;
    Offset pos = box.localToGlobal(Offset(0, 0));

    List<RenderParagraph> pars = <RenderParagraph>[];
    _findRenderParagraphs(obj, pars);

    // print('------------');
    // print(pos);

    TextSpanWrapper? target;
    RenderParagraph? targetPar;
    int targetOffset = 0;

    const double adjustX = 2;
    const double adjustY = 1;

    int start = -1;
    int end = -1;

    // find paragraph
    for (final p in pars) {
      if (target != null) {
        break;
      }

      RenderBox? pbox = p as RenderBox;
      Offset pPos = pbox.localToGlobal(Offset(0, 0));
      TextSpan _t = p.text as TextSpan;
      Rect bounds = Offset(0, 0) & p.size;

      if (pPos.dy + p.size.height < pos.dy) continue;
      if (pPos.dy > pos.dy + box.size.height) continue;

      List<InlineSpan>? _c = _t.children;
      for (final c in _c ?? []) {
        if (!(c is TextSpanWrapper)) continue;
        TextSpanWrapper tsw = c as TextSpanWrapper;
        if (start == -1) {
          start = tsw.line;
        }
        end = tsw.line;
      }
    }

    editorFirstLine = start;
    editorLastLine = end;
    return [start, end];
  }

  bool isLineVisible(int line) {
    getVisibleLines();
    return line >= editorFirstLine && line <= editorLastLine;
  }

  void scrollToLine(int line) {
    if (line < 0) line = 0;
    bool visible = isLineVisible(line);
    if (visible) {
      // print('block is visible');
      scrollToController.cancel();
    } else {
      int h = (editorLastLine - editorFirstLine);
      // print('scroll');
      int l = doc?.breaks.length ?? 0;
      double p = line.toDouble() / (l + 1);
      double target = (_scroller.position.maxScrollExtent + 1000) * p;
      double dir = (line - h / 2 < editorFirstLine) ? -10 : 10;

      target += (200 * dir);
      // print('${target} ${l}');

      scrollToController.speedScale = 0.02;
      scrollToController.onUpdate = (() {
        // end scroller when line becomes visible
        return !isLineVisible(line);
      });

      scrollToController.start(dir,
          scrollController: _scroller, target: target, loops: 200);
    }

    // print('$line $editorFirstLine, $editorLastLine');
  }

  void _findPositioned(RenderObject? obj, List<RenderPositionedBox> res) {
    if (obj is RenderPositionedBox) {
      res.add(obj);
    }
    obj?.visitChildren((child) {
      _findPositioned(child, res);
    });
  }

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
    int l = editor.hl().length;
    int idx = -1;
    for (int i = l - 1; i > -1; i--) {
      var hl = editor.hl()[i];
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
  }

  Offset _screenToCursor(List<RenderParagraph> pars, Offset pos) {
    RenderObject? obj = context.findRenderObject();
    if (this.doc == null || obj == null) return Offset(-1, -1);
    RenderBox? box = obj as RenderBox;

    // print('------------');
    // print(pos);

    TextSpanWrapper? target;
    RenderParagraph? targetPar;
    int targetOffset = 0;

    const double adjustX = 2;
    const double adjustY = 1;

    // find paragraph
    for (final p in pars) {
      if (target != null) {
        break;
      }

      RenderBox? pbox = p as RenderBox;
      Offset pPos = pbox.localToGlobal(Offset(0, 0));

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

      int nearestLine = 0;
      int nearestPosition = 0;
      double nearestDistance = -1;

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
            position = (span as TextSpanWrapper).pos + i;
            line = (span as TextSpanWrapper).index;
            break;
          }

          double dx = pos.dx - spanPos.dx;
          double dy = pos.dy - spanPos.dy;
          double d = dx * dx + dy * dy;
          if (d < nearestDistance || nearestDistance == -1) {
            nearestDistance = d;
            nearestPosition = (span as TextSpanWrapper).pos + i;
            nearestLine = (span as TextSpanWrapper).index;
          }
        }

        textOffset += _s.length;
        if (!found) {
          position = textOffset;
        }
      });

      if (!found) {
        line = nearestLine;
        position = nearestPosition;
      }

      return Offset(line.toDouble(), position.toDouble());
    }

    return Offset(-1, -1);
  }

  void _onScroll() {
    AppModel app = Provider.of<AppModel>(context, listen: false);
    EditorModel editor = Provider.of<EditorModel>(context, listen: false);
    bool scrolled = _scroller.position.pixels != 0;
    editor.showDocTool(!scrolled);
    if (app.isInnerScrolled != (scrolled)) {
      app.isInnerScrolled = (scrolled);
      app.notifyListeners();
    }
  }

  void _onTapDown(Widget child, Offset pos) {
    RenderObject? obj = context.findRenderObject();
    if (this.doc == null || obj == null) return;

    List<RenderPositionedBox> pbox = <RenderPositionedBox>[];
    _findPositioned(obj, pbox);
    for (int i = 0; i < pbox.length; i++) {
      RenderBox? box = pbox[i] as RenderBox;
      Rect bounds = Offset(0, 0) & box.size;
      Offset spanPos = box.localToGlobal(Offset(0, 0));
      if (pos.dx >= pos.dx &&
          pos.dx < pos.dx + bounds.width &&
          pos.dy >= spanPos.dy - 20 &&
          pos.dy < spanPos.dy + 20 + bounds.height) {
        // within toolbar
        return;
      }
    }

    List<RenderParagraph> pars = <RenderParagraph>[];
    _findRenderParagraphs(obj, pars);

    EditorModel editor = Provider.of<EditorModel>(context, listen: false);
    Offset offset = _screenToCursor(pars, pos);
    if (offset.dx > 0) {
      if (shifting) {
        end = offset;
        _updateLastSelection(start, end);
        return;
      } else {
        start = offset;
      }
      // var elm = this.doc?.elms[offset.dx.toInt()];
      // print((elm as Node).text);
      int hl = findHighlight(offset);
      editor.selectHighlight(hl);
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
      start = offset;
      EditorModel editor = Provider.of<EditorModel>(context, listen: false);
      editor.beginSelect(start, end);
    }
  }

  void _updateLastSelection(Offset p1, Offset p2) {
    if (p1.dx > p2.dx || (p1.dx == p2.dx && p1.dy > p2.dy)) {
      Offset p3 = p1;
      p1 = p2;
      p2 = p3;
    }

    EditorModel editor = Provider.of<EditorModel>(context, listen: false);
    editor.updateSelection(p1, p2);
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

  Widget buildTable(BuildContext context, int line, int start, int end) {
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
                flex: cells.length == 0 ? 1 : 3,
                child: RichText(
                    text: TextSpan(
                        children:
                            buildParagraphs(this.doc, editor.hl(), spans)))));
          }
          if (m.elm == '/tr') {
            rows.add(Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(children: cells)));
          }
        }
        if (elm is Node) {
          HtmlSpan span = HtmlSpan(
            line: line,
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

    // balance

    double padLeftRight = 80;
    return Padding(
        padding: EdgeInsets.only(
            left: padLeftRight, right: padLeftRight, bottom: 24),
        child: Column(children: rows));
  }

  Widget buildTextList(BuildContext context) {
    int? count = 1;

    List<Widget> children = <Widget>[];
    if (this.doc != null) {
      count = this.doc?.breaks.length;
      if (count != null) {
        count += 3;
      }
    }

    EditorModel editor = Provider.of<EditorModel>(context);
    return ListView.builder(
        controller: _scroller,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) {
          if (index == 0) {
            return documentHeader();
          }
          bool block = false;
          bool center = false;
          bool table = false;

          index--;

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
                  return buildTable(context, index, start, end);
                }
              }

              var elm = doc?.elms[i];
              if (elm != null) {
                if (elm is Node) {
                  HtmlSpan span = HtmlSpan(
                    line: index,
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
                        text: TextSpan(
                            children: buildParagraphs(
                                this.doc, editor.hl(), spans)))));
          }
          return Container();
        });
  }

  void _onKeyInputMods(bool shift, bool ctrl) {
    setState(() {
      shifting = shift;
      ctrling = ctrl;
    });
  }

  void _onKeyInputSequence(String text) {
    AppModel app = Provider.of<AppModel>(context, listen: false);
    EditorModel editor = Provider.of<EditorModel>(context, listen: false);
    switch (text) {
      case 'ctrl+1':
        editor.setColorByIndex(int.parse(text.split('+')[1]) - 1);
        break;
      case 'ctrl+2':
        editor.setColorByIndex(int.parse(text.split('+')[1]) - 1);
        break;
      case 'ctrl+3':
        editor.setColorByIndex(int.parse(text.split('+')[1]) - 1);
        break;
      case 'ctrl+4':
        editor.setColorByIndex(int.parse(text.split('+')[1]) - 1);
        break;
      case 'ctrl+x':
        editor.deleteHighlight(editor.currentHighlight());
        break;
      case 'ctrl+h':
        editor.toggleHighlight();
        break;
      case 'ctrl+=':
        app.textScale += 0.2;
        if (app.textScale > 1.8) {
          app.textScale = 1.8;
        }
        app.notifyListeners();
        break;
      case 'ctrl+-':
        app.textScale -= 0.2;
        if (app.textScale < 0.8) {
          app.textScale = 0.8;
        }
        app.notifyListeners();
        break;
    }
    print(text);
  }

  void scrollToSupPair(int index) {
    var elm = doc?.elms[index];
    if (!(elm is Node)) return;

    String sub = '${(elm as Node).text}';
    int start = -1;
    int end = -1;
    int l = doc?.elms.length ?? 0;
    for (int i = 0; i < l; i++) {
      elm = doc?.elms[i];
      if (!(elm is Node)) continue;
      String sub2 = '${(elm as Node).text}';
      if (sub == sub2) {
        if (start == -1) {
          start = i;
        } else {
          end = i;
        }
      }
      if (start > 0 && end > 0) {
        break;
      }
    }

    int overshoot = -4;
    int scrollTo = start;
    if (index == start) {
      scrollTo = end;
      overshoot = 4;
    }

    int idx = 0;
    for (final b in doc?.breaks ?? []) {
      if (b > scrollTo) {
        break;
      }
      idx++;
    }

    scrollToLine(idx);
    // print('${idx} ${start} ${end}');
  }

  List<InlineSpan> buildParagraphs(
      AnnotateDoc? doc, List<HL> hl, List<HtmlSpan> spans) {
    AppModel app = Provider.of<AppModel>(context, listen: false);

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
      if (s.text.length == 0) return;

      for (int i = 0; i < text.length; i++) {
        HtmlSpan ss = HtmlSpan(
          line: s.line,
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
          hl.forEach((hl) {
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

    if (debugParagraphs) {
      spns.add(TextSpanWrapper(
          text: '${start}-${end}', style: TextStyle(color: Colors.red)));
    }

    hld.forEach((s) {
      s.fontFamily = app.fontFamily;
      s.fontSize *= app.textScale;
      GestureRecognizer? recognizer;
      if (s.sup) {
        recognizer = TapGestureRecognizer()
          ..onTap = () {
            scrollToSupPair(s.index);
          };
      }
      spns.add(s.toTextSpan(doc, s.text, recognizer: recognizer));
    });
    return spns;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    List<Widget> children = [buildTextList(context)];

    [AnnotateTool()].forEach((t) => children.add(t));

    return KeyInputListener(
        focusNode: focusNode,
        // onKeyInputText: _onKeyInputText,
        onKeyInputSequence: _onKeyInputSequence,
        onKeyInputMods: _onKeyInputMods,
        child: TouchInputListener(
            onTapDown: _onTapDown,
            onDragStart: _onDragStart,
            onDragUpdate: _onDragUpdate,
            child: Stack(children: children)));
  }
}
