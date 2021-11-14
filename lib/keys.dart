import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final Map<LogicalKeyboardKey, String> keyMap = {
  LogicalKeyboardKey.backspace: 'backspace',
  LogicalKeyboardKey.delete: 'delete',
  LogicalKeyboardKey.enter: 'enter',
  LogicalKeyboardKey.arrowUp: 'up',
  LogicalKeyboardKey.arrowDown: 'down',
  LogicalKeyboardKey.arrowLeft: 'left',
  LogicalKeyboardKey.arrowRight: 'right',
  LogicalKeyboardKey.pageUp: 'pageup',
  LogicalKeyboardKey.pageDown: 'pagedown',
  LogicalKeyboardKey.home: 'home',
  LogicalKeyboardKey.end: 'end',
  LogicalKeyboardKey.tab: 'tab',
  LogicalKeyboardKey.escape: 'escape'
};

class KeyInputListener extends StatelessWidget {
  Widget child = Container();
  Function? onKeyInputText;
  Function? onKeyInputSequence;
  Function? onKeyInputMods;
  late FocusNode focusNode; //  = FocusNode();

  KeyInputListener(
      {Key? key,
      required Widget this.child,
      required FocusNode this.focusNode,
      Function? this.onKeyInputText,
      Function? this.onKeyInputSequence,
      Function? this.onKeyInputMods})
      : super(key: key);

  List ResolveKeyPress(RawKeyEvent event) {
    String ch = '${event.character}';
    String mod = '';

    if (event.isControlPressed) {
      mod = 'ctrl';
    }
    if (event.isAltPressed) {
      if (mod != '') {
        mod += '+';
      }
      mod += 'alt';
    }
    if (event.isShiftPressed) {
      if (mod != '') {
        mod += '+';
      }
      mod += 'shift';
    }

    keyMap.forEach((k, s) {
      if (event.isKeyPressed(k)) {
        if (mod != '') {
          mod += '+';
        }
        mod += s;
        ch = '';
      }
    });

    if (ch != 'null' && mod == 'shift') {
      mod = '';
    }
    if (mod != '') {
      ch = ch.toLowerCase();
    }
    return [mod, ch];
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
        focusNode: focusNode,
        onKey: (RawKeyEvent event) {
          if (event.runtimeType.toString() == 'RawKeyUpEvent') {
            if (onKeyInputMods != null) {
              onKeyInputMods?.call(false, false);
            }
            return;
          }

          List res = ResolveKeyPress(event);
          String mod = res[0] as String;
          String ch = res[1] as String;

          if (onKeyInputMods != null) {
            onKeyInputMods?.call((mod == 'shift'), (mod == 'ctrl'));
          }

          if (ch == 'null') ch = '';
          if (mod != '') {
            if (ch != '') {
              mod += '+$ch';
            } else if (mod == 'ctrl' ||
                mod == 'alt' ||
                mod == 'shift' ||
                mod == 'ctrl+shift' ||
                mod == 'ctrl+alt' ||
                mod == 'alt+shift') {
              return;
            }
            print('sequence: $mod');
            if (onKeyInputSequence != null) {
              onKeyInputSequence?.call(mod);
            }
          } else if (ch != '') {
            print(ch);
            if (onKeyInputText != null) {
              onKeyInputText?.call(ch);
            }
          }
        },
        autofocus: true,
        child: this.child);
  }
}
