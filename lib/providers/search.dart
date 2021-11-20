import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' show join;

import '../constants.dart';
import '../editor.dart';
import '../annotate.dart';
import '../cache.dart';
import '../util.dart';

class SearchModel extends ChangeNotifier {
  String searchHintText = 'Type query...';
  String query = '';
  var result;
  int offset = 0;
  int limits = 0;
  int count = 0;
  bool searching = false;

  String buildQuery(String query) {
    print('override me');
    return query;
  }

  void setResult(parsed) {
    print('??${parsed['count']}');
    this.result = parsed['result'];
    this.limits = parsed['limits'];
    this.offset = parsed['offset'];
    this.count = parsed['count'];
    print('count:${this.count} limits:${this.limits} offset:${this.offset}');
    notifyListeners();
  }

  void search(String query) {
    this.query = query;
    String q = buildQuery(query);

    searching = true;
    cachedHttpFetch(q, q, sessionOnly: false).then((result) {
      if (result != null) {
        var parsed = jsonDecode(result);
        if (parsed != null) {
          setResult(parsed);
        }
      }
      searching = false;
      notifyListeners();
    }).catchError((error) {
      searching = false;
      notifyListeners();
    });
  }
}
