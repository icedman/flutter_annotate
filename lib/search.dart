import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'providers.dart';
import 'editor.dart';

class SearchView extends StatefulWidget {
  SearchView(
      {Widget? this.title,
      SearchModel? this.searchModel,
      Function? this.onTapResult});

  Widget? title;
  SearchModel? searchModel;
  Function? onTapResult;

  @override
  _SearchView createState() => _SearchView(
      title: title, searchModel: searchModel, onTapResult: onTapResult);
}

class _SearchView extends State<SearchView> {
  _SearchView(
      {Widget? this.title,
      SearchModel? this.searchModel,
      Function? this.onTapResult});

  bool showSearch = true;

  Widget? title;
  SearchModel? searchModel;
  Function? onTapResult;

  Timer _debounce = Timer(Duration(milliseconds: 0), () {});

  void _search(String text) {
    searchModel?.search(text);
  }

  void search(String text) {
    _debounce.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () => _search(text));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = <Widget>[];
    AppModel app = Provider.of<AppModel>(context);

    Widget customSearchBar = title ?? Container();

    if (showSearch) {
      customSearchBar = TextField(
          autofocus: true,
          onChanged: (value) {
            search(value);
          },
          showCursor: true,
          decoration: InputDecoration(
            hintText: searchModel?.searchHintText ?? 'Type query...',
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
          // iconTheme: IconThemeData(
          //   color: Colors.black, //change your color here
          // ),

          // flexibleSpace: Container(
          //   color: Colors.white,
          //   child: Container(
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //             // borderRadius:
          //             //     BorderRadius.only(topLeft: const Radius.circular(8.0)),
          //           //   gradient: LinearGradient(begin: Alignment.topCenter, colors: [
          //           // Color(0xFF832685),
          //           // Color(0xFFC81379),
          //           // Color(0xFFFAF2FB)
          //           // ])
          //         ))
          // ),

          elevation: 0,
          title: customSearchBar,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  showSearch = !showSearch;
                });
              },
              icon: !showSearch
                  ? const Icon(Icons.search)
                  : const Icon(Icons.close),
            )
          ],
        ),
        body: SearchResult(searchModel: searchModel, onTapResult: onTapResult));
  }
}

class SearchResult extends StatelessWidget {
  SearchResult({SearchModel? this.searchModel, Function? this.onTapResult});

  SearchModel? searchModel;
  Function? onTapResult;

  Widget buildRow(BuildContext context, index) {
    AppModel app = Provider.of<AppModel>(context);
    var row = searchModel?.result?[index];
    return InkWell(
        onTap: () async {
          // print(row);
          // app.openCase('${row['caseid']}').then((id) {
          //   Navigator.pushNamed(context, '/juris');
          // });
          onTapResult?.call(row);
        },
        child: Padding(
            padding: EdgeInsets.all(0),
            child: Row(children: [
              Expanded(
                  flex: 5,
                  child: Row(children: [
                    Expanded(
                        flex: 1,
                        child: ListTile(
                            title: Text('${row['shortTitle']}',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${row['shortGR']}'))),
                    Container(
                        width: 120,
                        child: ListTile(
                            title: Text('${row['date']}'),
                            subtitle: Text('${row['ponente']}')))
                  ])),
              Expanded(
                  flex: 1,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                            onPressed: () {}, icon: const Icon(Icons.more_vert))
                      ]))
            ])));
  }

  @override
  Widget build(BuildContext context) {
    int count = 0;
    if (searchModel?.result != null) {
      count = searchModel?.result?.length ?? 0;
    }

    if (searchModel?.searching ?? false) {
      return Padding(padding: EdgeInsets.all(20), child: Text('Searching...'));
    }

    // return Text('${searchModel?.searching?'searching':searchModel?.result}');
    return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) {
          return buildRow(context, index);
        });
  }
}
