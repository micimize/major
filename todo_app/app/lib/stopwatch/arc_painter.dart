import 'package:flutter/material.dart';
import 'dart:math' as math;

enum ArcDirection {
  Clockwise,
  CounterClockwise,
}

class ArcPainter extends CustomPainter {
  ArcPainter({
    @required this.animation,
    @required this.backgroundColor,
    @required this.color,
    @required this.direction,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color backgroundColor, color;
  final ArcDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    assert(
      size.aspectRatio == 1.0,
      'ArcPainter must be painted inside a square instead of ${size}',
    );
    Paint paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2.0, paint);
    paint.color = color;
    double progress = (1.0 - animation.value) * 2 * math.pi;
    progress = direction == ArcDirection.Clockwise ? progress : -progress;
    canvas.drawArc(Offset.zero & size, math.pi * 1.5, -progress, false, paint);
  }

  @override
  bool shouldRepaint(ArcPainter old) {
    return animation.value != old.animation.value ||
        color != old.color ||
        backgroundColor != old.backgroundColor;
  }
}
