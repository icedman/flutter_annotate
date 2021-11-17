import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = TextStyle(fontWeight: FontWeight.bold);
    return Scaffold(
      appBar: AppBar(elevation: 0, title: Text('Lawyerly')),
      body: ListView(children: [
        InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/juris/search');
            },
            child: ListTile(title: Text('Cases', style: titleStyle))),
        InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/laws/search');
            },
            child: ListTile(title: Text('Laws', style: titleStyle))),
        InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/juris/search');
            },
            child: ListTile(title: Text('Notes', style: titleStyle))),
      ]),
    );
  }
}
