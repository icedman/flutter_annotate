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
import 'palette.dart';
import 'annotate.dart';
import 'providers.dart';
import 'editor.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    AppModel app = Provider.of<AppModel>(context);

    ThemeData themeData = ThemeData(
        fontFamily: app.fontFamily,
        brightness: Brightness.light,
        primarySwatch: Colors.grey,
        primaryColor: app.foreground,
        backgroundColor: app.background,
        scaffoldBackgroundColor: Colors.white);

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themeData,
        initialRoute: '/',
        routes: {
          '/': (context) =>
              DefaultTabController(length: app.docs.length, child: CasesView())
        }
        // home: DefaultTabController(
        //     length: app.docs.length, child: CasesView())
        );
  }
}

class CasesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = <Widget>[];
    AppModel app = Provider.of<AppModel>(context);
    app.docs.forEach((doc) {
      tabs.add(Tab(
          child: MultiProvider(providers: [
        ChangeNotifierProvider(create: (context) => EditorModel(doc: doc))
      ], child: Editor(doc: doc))));
    });
    return Scaffold(
        // appBar: AppBar(),
        body: TabBarView(children: tabs));
  }
}
