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
import './search.dart';

class CaseSearchModel extends SearchModel {
  CaseSearchModel() {
    searchHintText = 'Type case title or docket number...';
  }

  @override
  String buildQuery(String query) {
    return '${caseSearchURL}?q=${query}';
  }
}

class LawSearchModel extends SearchModel {
  LawSearchModel() {
    searchHintText = 'Type law title or reference number...';
  }

  @override
  String buildQuery(String query) {
    return '${lawSearchURL}?q=${query}';
  }
}
