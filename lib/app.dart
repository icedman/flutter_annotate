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
import 'editor.dart';
import 'home.dart';
import 'cases.dart';
import 'laws.dart';
import 'util.dart';

import 'providers/profile.dart';
import 'providers/search.dart';
import 'providers/lawyerly.dart';
import 'providers/editor.dart';
import 'providers/app.dart';

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
          cursorColor: Colors.black.withOpacity(.6),
          selectionHandleColor: Color(0xc0c0c0).withOpacity(1),
        ),
        scaffoldBackgroundColor: Colors.white);

    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => CaseSearchModel()),
          ChangeNotifierProvider(create: (context) => LawSearchModel())
        ],
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeData,
            initialRoute: '/',
            routes: {
              '/': (context) => Home(),
              '/juris/search': (context) => CaseSearchView(),
              '/juris': (context) => DefaultTabController(
                  initialIndex: app.initialTab,
                  length: app.docs.length,
                  child: CaseView()),
              '/laws/search': (context) => LawSearchView(),
              '/laws': (context) => DefaultTabController(
                  initialIndex: app.initialTab,
                  length: app.docs.length,
                  child: LawView())
            }));
  }
}
