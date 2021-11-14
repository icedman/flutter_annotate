import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class TouchInputListener extends StatelessWidget {
  Widget child = Container();

  Function? onTapDown;
  Function? onTapUp;
  Function? onDragStart;
  Function? onDragUpdate;
  Function? onDragEnd;

  Offset tapPosition = Offset(0, 0);

  TouchInputListener({
    Key? key,
    required Widget this.child,
    Function? this.onTapDown,
    Function? this.onTapUp,
    Function? this.onDragStart,
    Function? this.onDragUpdate,
    Function? this.onDragEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(gestures: <Type, GestureRecognizerFactory>{
      PanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
        () => PanGestureRecognizer(),
        (PanGestureRecognizer instance) {
          instance
            ..onStart = (DragStartDetails details) {
              if (this.onDragStart != null) {
                this.onDragStart?.call(child, details.globalPosition);
              }
            }
            ..onUpdate = (DragUpdateDetails details) {
              if (this.onDragUpdate != null) {
                this.onDragUpdate?.call(child, details.globalPosition);
              }
            }
            ..onEnd = (DragEndDetails details) {
              if (this.onDragEnd != null) {
                this.onDragEnd?.call(child, Offset(0, 0));
              }
            };
        },
      ),
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(), (TapGestureRecognizer instance) {
        instance
          ..onTapDown = (TapDownDetails details) {
            tapPosition = details.globalPosition;
            if (this.onTapDown != null) {
              this.onTapDown?.call(child, details.globalPosition);
            }
          };
      }),
    }, child: child);
  }
}
