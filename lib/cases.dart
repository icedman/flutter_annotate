import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'providers.dart';
import 'editor.dart';

class CaseView extends StatelessWidget {
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

class CaseSearchView extends StatefulWidget {
  @override
  _CaseSearchView createState() => _CaseSearchView();
}

class _CaseSearchView extends State<CaseSearchView> {
  bool showSearch = true;
  Icon customIcon = const Icon(Icons.search);

  Timer _debounce = Timer(Duration(milliseconds: 0), () {});

  void _search(String text) {
    CaseSearchModel cases =
        Provider.of<CaseSearchModel>(context, listen: false);
    cases.search(text);
  }

  void search(String text) {
    _debounce.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () => _search(text));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = <Widget>[];
    AppModel app = Provider.of<AppModel>(context);

    Widget customSearchBar = Text('Cases');
    if (showSearch) {
      customSearchBar = TextField(
          autofocus: true,
          onChanged: (value) {
            search(value);
          },
          showCursor: true,
          decoration: InputDecoration(
            hintText: 'Type case title or docket ...',
            hintStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontStyle: FontStyle.italic,
            ),
            border: InputBorder.none,
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ));
    }

    return Scaffold(
        appBar: AppBar(
          title: customSearchBar,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  showSearch = !showSearch;
                  if (showSearch) {
                    customIcon = const Icon(Icons.close);
                  } else {
                    customIcon = const Icon(Icons.search);
                  }
                });
              },
              icon: customIcon,
            )
          ],
        ),
        body: SearchResult());
  }
}

class SearchResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    CaseSearchModel cases = Provider.of<CaseSearchModel>(context);

    int count = 0;
    if (cases.result != null) {
      count = cases.result?.length ?? 0;
    }
    print(count);
    if (cases.searching) {
      return Padding(padding: EdgeInsets.all(20), child: Text('Searching...'));
    }

    // return Text('${cases.searching?'searching':cases.result}');
    return ListView.builder(
        // controller: _scroller,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) {
          var row = cases.result?[index];
          print(row);
          return ListTile(
              title: InkWell(
                  onTap: () {
                    print('hello ${row['caseid']}');
                  },
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('${row['title']}'))));
        });
  }
}
