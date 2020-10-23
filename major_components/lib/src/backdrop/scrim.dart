import 'package:flutter/material.dart';

class Scrim extends StatelessWidget {
  const Scrim({
    Key key,
    this.applied,
    this.child,
    this.opacity = 0.5,
    this.color = Colors.white,
    this.speed = const Duration(milliseconds: 200),
    this.curve = const Interval(0.0, 0.4, curve: Curves.easeInOut),
  }) : super(key: key);

  final bool applied;
  final Widget child;
  final Color color;
  final Interval curve;
  final double opacity;
  final Duration speed;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: applied,
      child: AnimatedContainer(
        duration: speed,
        curve: curve,
        foregroundDecoration: BoxDecoration(
          color: color.withOpacity(applied ? opacity : 0.0),
        ),
        child: child,
      ),
    );
  }
}
