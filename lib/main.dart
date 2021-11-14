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

import 'app.dart';
import 'providers.dart';
import 'touches.dart';
import 'annotate.dart';
import 'editor.dart';
import 'xpath.dart';

void main(List<String> args) async {
  AppModel app = AppModel();
  await app.configure(args);

  runApp(MultiProvider(
      providers: [
      ChangeNotifierProvider(create: (context) => app)
      ],
      child: App()
      ));
}
