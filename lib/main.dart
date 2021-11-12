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
import 'editor.dart';
import 'xpath.dart';

void main() async {
  File file = File('./article.html');

  String contents = await file.readAsString();
  var document = parse(contents);
  var doc = AnnotateDoc();
  var tree = AnnotateTreeVisitor();
  tree.doc = doc;
  tree.visit(document);

  XPath.findPath(doc, '/div[1]/blockquote[1]');
  XPath.findPath(doc, '/div/blockquote');

  runApp(Editor(doc: doc));
}
