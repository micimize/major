import 'package:flutter/material.dart';

/// fade and expand the [child] along the given [axis].
///
/// Defaults are tuned for the animation of the `top` of the [BackdropBar]
class PopIn extends StatelessWidget {
  const PopIn({
    Key key,
    @required this.animation,
    @required this.child,
    this.axis = Axis.vertical,
    this.fadeCurve = const Interval(0.25, 1.0, curve: Curves.easeInCubic),
    this.sizeCurve = Curves.easeOutCubic,
  }) : super(key: key);

  final Animation<double> animation;
  final Widget child;
  final Axis axis;

  final Curve fadeCurve;
  final Curve sizeCurve;

  @override
  Widget build(BuildContext context) {
    final fade = FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: fadeCurve,
      ),
      child: child,
    );

    return SizeTransition(
      axis: axis,
      axisAlignment: 1.0,
      sizeFactor: CurvedAnimation(
        parent: animation,
        curve: sizeCurve,
      ),
      child: fade,
    );
  }
}

// TODO will need animation mixin?
// future ref https://github.com/rrousselGit/flutter_hooks/blob/1bafe5c6ad96de9ff152abfe06fae7a1650c057b/lib/src/animation.dart
