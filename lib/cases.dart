import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'providers.dart';
import 'editor.dart';
import 'search.dart';

class CaseView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Widget> tabContent = <Widget>[];
    AppModel app = Provider.of<AppModel>(context);
    app.docs.forEach((doc) {
      tabContent.add(Tab(
          child: MultiProvider(providers: [
        ChangeNotifierProvider(create: (context) => EditorModel(doc: doc))
      ], child: Editor(doc: doc))));
    });

    return Scaffold(body: TabBarView(children: tabContent));
  }
}

class CaseSearchView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CaseSearchModel cases = Provider.of<CaseSearchModel>(context);
    AppModel app = Provider.of<AppModel>(context);
    Widget title = Text('Cases',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ));
    return SearchView(
        title: title,
        searchModel: cases,
        onTapResult: (item) async {
          app.openCase('${item['caseid']}').then((id) {
            Navigator.pushNamed(context, '/juris');
          });
        });
  }
}
