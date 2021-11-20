import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' show join;

import '../constants.dart';
import '../editor.dart';
import '../annotate.dart';
import '../cache.dart';
import '../util.dart';

class ProfileModel extends ChangeNotifier {
    ProfileModel() {
    }

    Future<bool> init() async {
        return true;
    }
}
