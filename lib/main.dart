import 'dart:io';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' show Node;
import 'package:html/dom_parsing.dart' show TreeVisitor;

import 'providers.dart';
import 'touches.dart';
import 'annotate.dart';
import 'editor.dart';
import 'xpath.dart';

void main() async {
  File file = File('./article.html');

  String contents = await file.readAsString();
  var document = parse(contents);
  var doc = AnnotateDoc(document);
  var tree = AnnotateTreeVisitor();
  tree.doc = doc;
  tree.visit(document);

  // {
  //   // e October 16, 2014 Decision[1] of the Court of Appeals (CA) in CA-G.R. CR. H.C. No. 06003, which affirmed the January 30, 2013 Decision[2] of the Regional Trial Court of Quezon City, Branch 227 (RTC), in Criminal Case No. Q-06-144570,
  //   Offset start = XPath.findPath(doc, '/div[1]', offset: 25);
  //   Offset end = XPath.findPath(doc, '/div[1]', offset: 259);
  //   doc.hl.add(HL(start: start, end: end));
  //   print(XPath.buildPath(doc, start));
  //   print(XPath.buildPath(doc, end));
  // }

  // {
  //   // sell, dispense, deliver[,] transport or distribute any dangerous drug, did then and there, willfully, and unlawfully sell, dispense, deliver, transport, distribute or act as broker in the said transaction, zero (0.06) point zero six [gram] of white crystalline substance containing Methylamphetamine Hydrochloride also known as "SHABU", a dangerou
  //   Offset start = XPath.findPath(doc, '/div[1]/blockquote[1]', offset: 127);
  //   Offset end = XPath.findPath(doc, '/div[1]/blockquote[1]', offset: 474);
  //   doc.hl.add(HL(start: start, end: end));
  //   print(XPath.buildPath(doc, start));
  //   print(XPath.buildPath(doc, end));
  // }

  // {
  //   // nviction before the CA, ar
  //   Offset start = XPath.findPath(doc, '/div[1]', offset: 5674);
  //   Offset end = XPath.findPath(doc, '/div[1]', offset: 5700);
  //   doc.hl.add(HL(start: start, end: end));
  //   print(XPath.buildPath(doc, start));
  //   print(XPath.buildPath(doc, end));
  // }

  final editorModel = EditorModel();
  editorModel.doc = doc;
  runApp(MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => editorModel)],
      child: Editor(doc: doc)));
}
