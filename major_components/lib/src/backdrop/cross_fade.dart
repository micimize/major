import 'package:flutter/material.dart';

Widget crossFade(
  bool isOpen,
  AnimationController controller,
  Widget back,
  Widget front, {
  AlignmentDirectional alignment = AlignmentDirectional.centerStart,
  bool namesRoute = true,
}) {
  return back != null && front != null
      ? CrossFadeTransition(
          // TODO this was buggy at some point but idk why.
          // without a key, titles do not properly transition (_switcher in BackdropBar)
          // but this key is probably incorrect
          key: Key(
            'crossfade(${back.key ?? back.hashCode}, ${front.key ?? front.hashCode})',
          ),
          progress: controller,
          alignment: alignment,
          firstChild: actionable(
            enabled: isOpen,
            namesRoute: namesRoute,
            child: back,
          ),
          secondChild: actionable(
            enabled: !isOpen,
            namesRoute: namesRoute,
            child: front,
          ),
        )
      : back ?? front;
}

/// Wraps `child` in a semantically aware pointer event swallower controlled by `enabled`.
Semantics actionable({bool enabled, bool namesRoute = true, Widget child}) =>
    Semantics(
        enabled: enabled,
        namesRoute: namesRoute,
        child: IgnorePointer(
          ignoring: !enabled,
          child: child,
        ));

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
