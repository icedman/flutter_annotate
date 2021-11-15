import 'dart:async';
import 'package:flutter/material.dart';

class ScrollTo {
  Timer? periodic;
  Function? onUpdate;
  Function? onDone;
  ScrollController? scrollController;
  double direction = 0;
  double target = 0;
  double speedScale = 1;
  int loops = 0;

  void start(double direction,
      {ScrollController? scrollController, double target = 0, int loops = 0}) {
    this.scrollController = scrollController;
    this.direction = direction;
    this.loops = loops;
    this.target = target;
    if (periodic == null) {
      periodic = Timer.periodic(const Duration(milliseconds: 25), (timer) {
        update();
      });
    }
  }

  void update() {
    if (loops > 0) {
      // print(loops);
      loops--;
      if (loops == 0) {
        cancel();
      }
    }
    if (onUpdate != null) {
      if (onUpdate?.call() == false) {
        cancel();
        return;
      }
    }

    double? position = scrollController?.position.pixels;
    double? max = scrollController?.position.maxScrollExtent;
    if (position != null && max != null) {
      double speed = 20;
      double d = (position - target);

      // correct direction
      if (target != 0) {
        if (position > speed && position < max - (speed * 4)) {
          if (d > 0 && this.direction > 0) {
            this.direction *= -0.25;
          }
          if (d < 0 && this.direction < 0) {
            this.direction *= -0.25;
          }
        }
      }

      if (d < 0) d *= -1;
      speed *= (d / 300);
      if (speed > (max / 4)) speed = (max / 4);
      if (speed < 24) speed = 24;
      position += this.direction * speed * speedScale;
      if (position < 0) {
        position = 0;
        cancel();
      }
      if (max != null && position > max) {
        position = max;
        cancel();
      }
      scrollController?.jumpTo(position);
    }
  }

  void cancel() {
    if (periodic != null) {
      periodic?.cancel();
      periodic = null;
      loops = 0;
      onDone?.call();
    }
  }

  bool isRunning() {
    return (periodic != null);
  }
}
