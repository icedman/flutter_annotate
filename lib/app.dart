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
import 'annotate.dart';
import 'providers.dart';
import 'editor.dart';
import 'cases.dart';
import 'util.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    AppModel app = Provider.of<AppModel>(context);

    ThemeData themeData = ThemeData(
        // fontFamily: app.fontFamily,
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        primaryColor: app.foreground,
        backgroundColor: app.background,
        textSelectionTheme: TextSelectionThemeData(
          selectionColor: Color(0xc0c0c0).withOpacity(.5),
          cursorColor: Color(0xffffff).withOpacity(.6),
          selectionHandleColor: Color(0xc0c0c0).withOpacity(1),
        ),
        scaffoldBackgroundColor: Colors.white);

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themeData,
        initialRoute: '/juris/search',
        routes: {
          '/': (context) =>
              DefaultTabController(length: app.docs.length, child: CaseView()),
          '/juris/search': (context) => CaseSearchView()
        });
  }
}
