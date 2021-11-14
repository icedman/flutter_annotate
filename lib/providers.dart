import 'dart:ffi';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'editor.dart';
import 'annotate.dart';

const String appResourceRoot = '~/.lawyerly';
const Color selectionColor = Color.fromRGBO(0xc0, 0xc0, 0xc0, 1);

class EditorModel extends ChangeNotifier {
  EditorModel({AnnotateDoc? this.doc = null});
  AnnotateDoc? doc;

  bool enableDocTool = true;
  bool enableHighlight = false;
  int _highlightIndex = -1;
  Color _color = Colors.black;
  int _colorIndex = 0;
  List<HL> _hl = <HL>[];
  HL selection = HL();
  bool selectTag = false;

  List<Color> colors = <Color>[
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple
  ];

  void customizeColors(List<Color> colors) {
    this.colors = colors;
  }

  Color colorCombine(Color a, Color b) {
    return Color.fromRGBO((a.red + b.red) >> 1, (a.green + b.green) >> 1,
        (a.blue + b.blue) >> 1, 1);
  }

  Color currentColor() {
    if (_color == Colors.black) {
      _color = colors[0];
    }
    return _color;
  }

  void addHighlight() {
    selection.color = currentColor();
    selection.colorIndex = _colorIndex;
    _hl.add(selection);
    selectHighlight(_hl.length - 1);
    selection = HL();
    notifyListeners();
    // print(_hl.length);
  }

  void selectHighlight(int index) {
    _highlightIndex = index;
    selection = HL();
    notifyListeners();
  }

  void deleteHighlight(int index) {
    if (index != -1 && index < _hl.length) {
      _hl.removeAt(index);
      _highlightIndex = -1;
      notifyListeners();
    }
  }

  int count() {
    return _hl.length;
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
      if (_hl.length > 0) {
        _hl[_hl.length - 1].start = start;
        _hl[_hl.length - 1].end = end;
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
    } else if (currentHighlight() != -1 && currentHighlight() < _hl.length) {
      _hl[currentHighlight()].color = color;
      _hl[currentHighlight()].colorIndex = index;
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
    List<HL> res = [..._hl, selection].toList();
    if (hasSelection()) {
      selection.color = enableHighlight ? currentColor() : selectionColor;
      res.add(selection);
    }

    if (_highlightIndex != -1 && _highlightIndex < _hl.length) {
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
    await openEditor('./article.html');
    return true;
  }

  Future<int> openEditor(String path) async {
    AnnotateDoc doc = AnnotateDoc();
    await doc.load(path);
    docs.add(doc);

    loadAppConfig();
    notifyListeners();
    return 0;
  }

  void closeEditor(int uid) {
    notifyListeners();
  }

  void loadAppConfig() {}
}
