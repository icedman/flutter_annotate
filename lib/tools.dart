import 'dart:io';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'keys.dart';
import 'touches.dart';
import 'annotate.dart';
import 'providers.dart';

const double paragraphSpacing = 24;
const double iconSize = 32;
const double iconPadding = 8;
const int animationDuration = 320;

class AnnotateTool extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    EditorModel editor = Provider.of<EditorModel>(context);
    double opacity = (!editor.enableHighlight &&
            !editor.hasSelection() &&
            editor.currentHighlight() == -1)
        ? 0
        : 1;

    final target = editor.currentHighlight();

    List<Widget> colorIcons =
        List<int>.generate(editor.colors.length, (i) => i).map((c) {
      return GestureDetector(
          onTap: () {
            editor.selectTag = false;
            editor.setColorByIndex(c);
          },
          child: Padding(
              padding: EdgeInsets.all(iconPadding),
              child:
                  Icon(Icons.sell, color: editor.colors[c], size: iconSize)));
    }).toList();

    List<Widget> moreIcons = <Widget>[];
    if (editor.currentHighlight() != -1 &&
        editor.currentHighlight() < editor.count()) {
      moreIcons = <Widget>[
        GestureDetector(
            onTap: () {
              editor.deleteHighlight(editor.currentHighlight());
            },
            child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.delete_forever,
                    color: Colors.white, size: iconSize)))
      ];
    }

    return Positioned(
        left: 20,
        top: 20,
        child: Container(
            height: iconSize + iconPadding * 2,
            color: Colors.transparent,
            child: AnimatedOpacity(
              opacity: opacity,
              duration: Duration(milliseconds: animationDuration),
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius:
                          BorderRadius.all(const Radius.circular(8.0))),
                  child: Center(
                      child: opacity == 0
                          ? Container()
                          : Row(children: [
                              // Text('  ${editor.currentHighlight()}/${editor.count()} ${editor.hasSelection()}  ', style:TextStyle(color:Colors.white)),
                              GestureDetector(
                                  onTap: () {
                                    editor.toggleHighlight();
                                  },
                                  child: Padding(
                                      padding: EdgeInsets.all(iconPadding),
                                      child: Icon(Icons.border_color,
                                          color: editor.enableHighlight
                                              ? editor.currentColor()
                                              : Colors.white,
                                          size: iconSize))),
                              ...colorIcons,
                              ...moreIcons,
                            ]))),
            )));
  }
}
