import 'dart:ffi';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' show join;

import 'editor.dart';
import 'annotate.dart';
import 'cache.dart';
import 'util.dart';

const String appResourceRoot = '~/.lawyerly';
const Color selectionColor = Color.fromRGBO(0xc0, 0xc0, 0xc0, 1);

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class EditorModel extends ChangeNotifier {
  EditorModel({AnnotateDoc? this.doc = null}) {
    if (this.doc != null) {
      this.colors = this.doc?.colors ?? [];
    }
  }

  AnnotateDoc? doc;

  bool enableDocTool = true;
  bool enableHighlight = false;
  int _highlightIndex = -1;
  Color _color = Colors.black;
  int _colorIndex = 0;
  HL selection = HL();
  bool selectTag = false;

  List<Color> colors = <Color>[
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple
  ];

  Color currentColor() {
    if (_color == Colors.black) {
      _color = colors[0];
    }
    return _color;
  }

  void addHighlight() {
    selection.color = currentColor();
    selection.colorIndex = _colorIndex;
    doc?.hl.add(selection);
    selectHighlight(count() - 1);
    selection = HL();
    notifyListeners();
    // print(doc?.hl.length);
  }

  void selectHighlight(int index) {
    _highlightIndex = index;
    selection = HL();
    notifyListeners();
  }

  void deleteHighlight(int index) {
    if (index != -1 && index < count()) {
      doc?.hl.removeAt(index);
      _highlightIndex = -1;
      notifyListeners();
    }
  }

  int count() {
    return doc?.hl.length ?? 0;
  }

  int currentHighlight() {
    return _highlightIndex;
  }

  void toggleHighlight() {
    enableHighlight = !enableHighlight;
    if (enableHighlight && hasSelection()) {
      addHighlight();
    }
    notifyListeners();
  }

  void showDocTool(bool show) {
    if (show != enableDocTool) {
      enableDocTool = show;
      notifyListeners();
    }
  }

  void beginSelect(Offset start, Offset end) {
    HL sel = HL()
      ..start = start
      ..end = start
      ..color = selectionColor;
    selection = sel;
    notifyListeners();
    if (enableHighlight) {
      addHighlight();
    }
  }

  void endSelect() {
    selection = HL();
    notifyListeners();
  }

  void updateSelection(Offset start, Offset end) {
    selection.start = start;
    selection.end = end;
    if (enableHighlight) {
      if (count() > 0) {
        doc?.hl[count() - 1].start = start;
        doc?.hl[count() - 1].end = end;
      }
    }
    notifyListeners();
  }

  void setColorByIndex(int index) {
    if (index >= colors.length) {
      return;
    }
    print(index);
    Color color = colorCombine(Colors.white, colors[index]);
    this._color = color;
    this._colorIndex = index;
    if (hasSelection()) {
      addHighlight();
    } else if (currentHighlight() != -1 && currentHighlight() < count()) {
      doc?.hl[currentHighlight()].color = color;
      doc?.hl[currentHighlight()].colorIndex = index;
      _highlightIndex = -1;
    }
    notifyListeners();
  }

  bool hasSelection() {
    return (selection.start.dx != -1 &&
        selection.start.dy != -1 &&
        selection.end.dx != -1 &&
        selection.end.dy != -1);
  }

  List<HL> hl() {
    List<HL> res = [...((doc?.hl ?? []).toList()), selection].toList();
    if (hasSelection()) {
      selection.color = enableHighlight ? currentColor() : selectionColor;
      res.add(selection);
    }

    if (_highlightIndex != -1 && _highlightIndex < count()) {
      res[_highlightIndex] = HL()
        ..start = res[_highlightIndex].start
        ..end = res[_highlightIndex].end
        ..color = colors[res[_highlightIndex].colorIndex]
        ..colorIndex = res[_highlightIndex].colorIndex;
    }

    return res;
  }
}

class AppModel extends ChangeNotifier {
  List<String> args = <String>[];
  List<AnnotateDoc> docs = <AnnotateDoc>[];

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
    openEditor('https://lawyerly.ph/api-01/juris/view/cfc47').then((doc) {
      if (doc != null) {
        docs.add(doc);
        notifyListeners();

        doc.loadAnnotationFile('./annotations.json').then((success) {
          if (success) {
            // updateHLColors();
            notifyListeners();
          }
        });
      } else {
        print('unable to load content');
        return -1;
      }
    });

    return true;
  }

  Future<AnnotateDoc?> openEditor(String path) {
    // check if already opened

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

class CaseSearchModel extends ChangeNotifier {
  String query = '';
  var result;
  int offset = 0;
  int limits = 0;
  int count = 0;
  bool searching = false;

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
    String q = 'https://lawyerly.ph/api-01/juris/search?q=${query}';

    searching = true;
    cachedHttpFetch(q, q, sessionOnly: false).then((result) {
      // people vs sanchez
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
