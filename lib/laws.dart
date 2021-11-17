import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'providers.dart';
import 'editor.dart';
import 'search.dart';

class LawView extends StatelessWidget {
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

class LawSearchView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LawSearchModel cases = Provider.of<LawSearchModel>(context);
    AppModel app = Provider.of<AppModel>(context);
    Widget title = Text('Laws',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ));
    return SearchView(
        title: title,
        searchModel: cases,
        onTapResult: (item) async {
          print(item);
          app.openLaw('${item['lawid']}').then((id) {
            Navigator.pushNamed(context, '/laws');
          });
        });
  }
}
