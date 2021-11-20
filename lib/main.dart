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
import 'touches.dart';
import 'annotate.dart';
import 'editor.dart';
import 'cases.dart';
import 'laws.dart';
import 'xpath.dart';
import 'cache.dart';

import 'providers/search.dart';
import 'providers/lawyerly.dart';
import 'providers/editor.dart';
import 'providers/app.dart';
import 'providers/profile.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();
  initDB();
  await openDB();

  AppModel app = AppModel();
  await app.configure(args);

  ProfileModel profile = ProfileModel();
  await profile.init();

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => profile),
        ChangeNotifierProvider(create: (context) => app)
      ],
      child: App()));
}
