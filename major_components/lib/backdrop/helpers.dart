// ORIGINAL LICENSE:
// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import './cross_fade.dart';

/// Absorbs tap events unless the `controller.status == status`
class TappableWhileStatusIs extends StatefulWidget {
  const TappableWhileStatusIs(
    this.status, {
    Key key,
    this.controller,
    this.child,
  }) : super(key: key);

  final Widget child;
  final AnimationController controller;
  final AnimationStatus status;

  @override
  TappableWhileStatusIsState createState() => TappableWhileStatusIsState();
}

class TappableWhileStatusIsState extends State<TappableWhileStatusIs> {
  bool _active;

  @override
  void dispose() {
    widget.controller.removeStatusListener(_handleStatusChange);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addStatusListener(_handleStatusChange);
    _active = widget.controller.status == widget.status;
  }

  void _handleStatusChange(AnimationStatus status) {
    final bool value = widget.controller.status == widget.status;
    if (_active != value) {
      setState(() {
        _active = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !_active,
      child: widget.child,
    );
  }
}

class Scrim extends StatelessWidget {
  const Scrim({
    Key key,
    this.applied,
    this.child,
    this.opacity = 0.75,
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

/// Wraps `child` in a semantically aware pointer event swallower controlled by `enabled`.
Semantics actionable({bool enabled, bool namesRoute = true, Widget child}) =>
    Semantics(
        enabled: enabled,
        namesRoute: namesRoute,
        child: IgnorePointer(
          ignoring: !enabled,
          child: child,
        ));

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

class PopIn extends StatelessWidget {
  const PopIn({
    Key key,
    @required this.animation,
    @required this.child,
    this.axis = Axis.vertical,
  }) : super(key: key);

  final Animation<double> animation;
  final Widget child;
  final Axis axis;

  Curve directed(Curve curve) =>
      (animation is ReverseAnimation) ? curve.flipped : curve;

  @override
  Widget build(BuildContext context) {
    if (animation is ReverseAnimation) print(animation);
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

  static PopIn transitionBuilder(
    Widget child,
    Animation<double> animation,
  ) =>
      PopIn(animation: animation, child: child);

  static const fadeCurve = Interval(0.25, 1.0, curve: Curves.easeInCubic);
  static const sizeCurve = Curves.easeOutCubic;
}

class AnimatedPopIn extends StatelessWidget {
  const AnimatedPopIn({
    Key key,
    this.duration = const Duration(milliseconds: 550),
    this.child,
    this.switchInCurve = const Interval(0.375, 1.0, curve: Curves.easeIn),
    this.switchOutCurve = const Interval(0.375, 1.0, curve: Curves.easeOut),
  }) : super(key: key);

  final Widget child;
  final Duration duration;
  final Curve switchInCurve;
  final Curve switchOutCurve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: PopIn.transitionBuilder,
      child: child,
    );
  }
}

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

// closely coupled
class TabSwitcher extends StatelessWidget {
  const TabSwitcher({
    this.isOnTop,
    Key key,
    this.duration = const Duration(
        milliseconds: 300), // TODO idk why tab speed is so much faster
    this.child,
  }) : super(key: key);

  final Widget child;
  final Duration duration;
  final bool isOnTop;

  Curve direct(Curve c) => isOnTop ? c : c.flipped;

  Widget _slide(
    Widget child,
  ) =>
      TweenAnimationBuilder(
        duration: duration,
        curve: Curves.easeOutQuad,
        tween: isOnTop
            ? Tween(
                begin: Offset(0, 0.5),
                end: Offset.zero,
              )
            : Tween(
                begin: Offset.zero,
                end: Offset(0, 0.5),
              ),
        builder: (BuildContext context, Offset offset, Widget child) {
          return FractionalTranslation(
            translation: offset,
            transformHitTests: true,
            child: child,
          );
        },
        child: child,
      );

  Widget _fade(Widget child) => AnimatedOpacity(
        opacity: isOnTop ? 1 : 0,
        duration: duration,
        curve: isOnTop
            ? Interval(
                0.5,
                1.0,
                curve: Curves.easeIn,
              )
            : Interval(
                0.0,
                0.5,
                curve: Curves.easeOut,
              ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    //final p = TabNavigator.focusOf(context).tabNavigator.currentPath;
    //print([isOnTop, p, p.pointsTo(context)]);
    return _slide(_fade(child));
  }
}

class AnimationProvider extends StatefulWidget {
  @override
  _AnimationProviderState createState() => _AnimationProviderState();
}

class _AnimationProviderState extends State<AnimationProvider> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
