import 'package:flutter/material.dart';

/// fade between two widgets
///
/// extracted from backdrop demo
class CrossFadeTransition extends AnimatedWidget {
  const CrossFadeTransition({
    Key key,
    this.alignment = Alignment.center,
    Animation<double> progress,
    this.firstChild,
    this.secondChild,
  }) : super(key: key, listenable: progress);

  final AlignmentGeometry alignment;

  /// Widget displayed at progress.value == 0
  final Widget firstChild;

  /// Widget displayed at progress.value == 1
  final Widget secondChild;

  @override
  Widget build(BuildContext context) {
    final Animation<double> progress = listenable as Animation<double>;

    final double opacity1 = CurvedAnimation(
      parent: ReverseAnimation(progress),
      curve: const Interval(0.5, 1.0),
    ).value;

    final double opacity2 = CurvedAnimation(
      parent: progress,
      curve: const Interval(0.5, 1.0),
    ).value;

    return Stack(
      alignment: alignment,
      children: <Widget>[
        Opacity(
          opacity: opacity1,
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            child: secondChild,
          ),
        ),
        Opacity(
          opacity: opacity2,
          child: Semantics(
            scopesRoute: true,
            explicitChildNodes: true,
            child: firstChild,
          ),
        ),
      ],
    );
  }
}
