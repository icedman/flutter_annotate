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


const String appResourceRoot = '~/.lawyerly';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class AppModel extends ChangeNotifier {
  List<String> args = <String>[];
  List<AnnotateDoc> docs = <AnnotateDoc>[];
  int initialTab = 0;

  String explorerRoot = '~/';
  String editFilePath = '';

  // settings
  int tabSize = 4;
  bool showStatusbar = false;
  bool showGutter = false;
  bool showTabbar = false;
  bool showSidebar = false;
  bool showMinimap = false;
  bool openSidebar = false;

  bool isInnerScrolled = false;

  // theme
  String themePath = '';
  String fontFamily = 'Times';
  double textScale = 1.2;

  Color foreground = Colors.white;
  Color background = Colors.grey;
  Color selectionBackground = Colors.yellow;
  Color comment = Colors.yellow;

  // ready
  bool resourcesReady = false;
  // permissions
  PermissionStatus permissionStatus = PermissionStatus.denied;

  // extensions

  void setTheme(path) {
    this.themePath = path;
    loadTheme();
  }

  void loadTheme() {}

  Future<void> setupResources() async {
    // if (permissionStatus != PermissionStatus.granted) return;
    // var configPath = EditorApi.expandPath('$appResourceRoot/config.json');
    // bool exists = File(configPath).existsSync();
    // if (!exists) {
    //   // print('create app resource directory');
    //   await extractArchive(
    //       'extensions.zip', EditorApi.expandPath('$appResourceRoot/'));

    //   String default_config_text =
    //       await getTextFileFromAsset('config.default.json');
    //   final config_default = await File(
    //       EditorApi.expandPath('$appResourceRoot/config.default.json'));
    //   await config_default.writeAsString(default_config_text);

    //   String config_text = await getTextFileFromAsset('config.json');
    //   final config =
    //       await File(EditorApi.expandPath('$appResourceRoot/config.json'));
    //   await config.writeAsString(config_text);
    //   resourcesReady = true;
    // } else {
    //   resourcesReady = true;
    // }

    resourcesReady = true;
  }

  bool isReady() {
    return resourcesReady && permissionStatus == PermissionStatus.granted;
  }

  String preReadyMessage() {
    if (permissionStatus != PermissionStatus.granted) {
      return 'Please grant storage access and restart.';
    }
    return 'Preparing resources...';
  }

  Future<void> queryPermission() async {
    try {
      final status = await Permission.manageExternalStorage.request();
      if (status == PermissionStatus.permanentlyDenied) {
        print('Permission permanently denied.');
        await openAppSettings();
      }
      permissionStatus = status;

      // for android 10 and below
      if (status == PermissionStatus.restricted) {
        final status = await Permission.storage.request();
        if (status == PermissionStatus.permanentlyDenied) {
          print('Permission permanently denied.');
          await openAppSettings();
        }
        permissionStatus = status;
      }
    } catch (error, msg) {
      permissionStatus = PermissionStatus.granted;
    }
  }

  Future<bool> configure(List<String> args) async {
    // if (!EditorApi.checkStorageAccess('$appResourceRoot/config.json')) {
    //   print('check permissions');
    //   await queryPermission();
    //   notifyListeners();
    //   await setupResources();
    //   notifyListeners();
    // } else {
    //   print('permission may have been granted already');
    resourcesReady = true;
    permissionStatus = PermissionStatus.granted;
    // }

    // if (args.length > 0) {
    //   explorerRoot = File(args[0]).path;
    //   editFilePath = args[0];
    // } else {
    //   editFilePath = '~/.editor/config.json';
    // }

    // EditorApi.initialize(appResourceRoot, explorerRoot);
    // loadTheme();
    // await openEditor('./article.html');
    // await openEditor('./cfc47.json');
    // openEditor('https://lawyerly.ph/api-01/juris/view/cfc47').then((doc) {
    //   if (doc != null) {
    //     docs.add(doc);
    //     notifyListeners();

    //     doc.loadAnnotationFile('./annotations.json').then((success) {
    //       if (success) {
    //         // updateHLColors();
    //         notifyListeners();
    //       }
    //     });
    //   } else {
    //     print('unable to load content');
    //     return -1;
    //   }
    // });

    return true;
  }

  Future<int> openCase(String caseId) {
    for (int i = 0; i < docs.length; i++) {
      if (docs[i].docId == caseId) {
        initialTab = i;
        return Future<int>.value(i);
      }
    }
    // find existing
    String url = '${caseViewURL}/${caseId}';
    return openEditor(url).then((doc) {
      if (doc != null) {
        doc.docType = 0;
        docs.add(doc);
        doc.docId = caseId;
        doc.sourceUrl = url;
        notifyListeners();

        // doc.loadAnnotationFile('./annotations.json').then((success) {
        String annotationsUrl =
            '${annotationSearchURL}?docid=${caseId}&doctype=case&user=1';
        // print(annotationsUrl);
        doc.loadAnnotationHttp(annotationsUrl).then((success) {
          if (success) {
            notifyListeners();
          }
        });

        initialTab = docs.length - 1;
        return docs.length - 1;
      } else {
        print('unable to load content');
        return -1;
      }
    });

    // return -1;
  }

  Future<int> openLaw(String lawId) {
    for (int i = 0; i < docs.length; i++) {
      if (docs[i].docId == lawId) {
        initialTab = i;
        return Future<int>.value(i);
      }
    }
    // find existing
    String url = '${lawViewURL}/${lawId}';
    return openEditor(url).then((doc) {
      if (doc != null) {
        doc.docType = 1;
        docs.add(doc);
        doc.docId = lawId;
        doc.sourceUrl = url;
        notifyListeners();

        // doc.loadAnnotationFile('./annotations.json').then((success) {
        String annotationsUrl =
            '${annotationSearchURL}?docid=${lawId}&doctype=law&user=1';
        // print(annotationsUrl);
        doc.loadAnnotationHttp(annotationsUrl).then((success) {
          if (success) {
            notifyListeners();
          }
        });

        initialTab = docs.length - 1;
        return docs.length - 1;
      } else {
        print('unable to load content');
        return -1;
      }
    });

    // return -1;
  }

  Future<AnnotateDoc?> openEditor(String path) {
    if (path.contains('.html')) {
      return AnnotateDoc.loadFile(path);
    }
    return AnnotateDoc.loadHttp(path);
  }

  void closeEditor(int uid) {
    notifyListeners();
  }

  void loadAppConfig() {}
}
