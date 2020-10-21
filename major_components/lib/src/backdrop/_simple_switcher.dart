import 'package:flutter/material.dart';

// TODO make open state based
class SimpleSwitcher extends StatelessWidget {
  const SimpleSwitcher({
    Key key,
    this.duration = const Duration(milliseconds: 550),
    this.child,
    this.alignment = Alignment.topCenter,
    this.switchInCurve = const Interval(0.375, 1.0, curve: Curves.easeIn),
    this.switchOutCurve = const Interval(0.375, 1.0, curve: Curves.easeOut),
    this.sizeCurve = const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    this.fadeCurve = const Interval(0.6, 1.0, curve: Curves.easeOut),
  }) : super(key: key);

  final Alignment alignment;
  final Axis axis = Axis.vertical;
  final double axisAlignment = -1.0;
  final Widget child;
  final Duration duration;
  final Curve fadeCurve;
  final Curve sizeCurve;
  final Curve switchInCurve;
  final Curve switchOutCurve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(
          axis: axis,
          axisAlignment: axisAlignment,
          sizeFactor: CurvedAnimation(
            curve: sizeCurve,
            parent: animation,
          ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              curve: fadeCurve,
              parent: animation,
            ),
            child: Align(alignment: alignment, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

SimpleSwitcher switcher(Widget item) => SimpleSwitcher(
      alignment: Alignment.centerLeft,
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      duration: Duration(milliseconds: 250),
      sizeCurve: Interval(0.0, 0.5, curve: Curves.linear),
      fadeCurve: Interval(0.5, 1.0, curve: Curves.linear),
      child: item ?? SizedBox(width: 0, height: 0),
    );
