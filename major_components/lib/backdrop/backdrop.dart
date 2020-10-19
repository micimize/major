// ORIGINAL LICENSE:
// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../big_sheet.dart';

import './helpers.dart';
import '../tab_navigator.dart';

import './backdrop_state_provider.dart';
export './backdrop_state_provider.dart';

part './backdrop_controller.dart';
part './backdrop_bar.dart';
part './leading_toggle_button.dart';

// const double _kFrontHeadingHeight = 32.0; // front layer beveled rectangle
const double frontClosedHeight = 92.0; // front layer height when closed

class Backdrop extends StatefulWidget {
  const Backdrop({
    this.bar,
    this.frontHeading,
    this.frontLayer,
    this.backLayer,
    this.openState,
    Key key,
  }) : super(key: key);

  ///
  final BackdropBar bar;

  final Widget backLayer;
  final Widget frontLayer;

  final Widget frontHeading;

  final BackdropOpenState openState;

  @override
  _BackdropState createState() => _BackdropState();

  static _BackdropState of(
    BuildContext context, {
    bool isNullOk = false,
  }) {
    assert(isNullOk != null);
    assert(context != null);
    final _BackdropState result =
        context.findAncestorStateOfType<_BackdropState>();
    if (isNullOk || result != null) {
      return result;
    }
    throw FlutterError(
      'Backdrop.of() called with a context that does not contain a Backdrop.\n',
    );
  }
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin {
  // TODO It's awkward to have both controller-driven and in-place duration-driven animations
  // TODO Maybe we should just replace the controller with top-level durations and curves?

  bool get isOpen => widget.openState.isOpen;
  AnimationController get controller => widget.openState.controller;
  ValueChanged<bool> get onOpenChanged => widget.openState.onOpenChanged;

  AnimationController _peakController;

  // Animation<double> _frontOpacity;

  bool onTop = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isOpen) {
        controller.value = 0.0;
      }
    });

    _peakController = AnimationController(vsync: this)..value = 1;

    // _frontOpacity = controller.drive(_frontOpacityTween);
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (oldWidget.openState.isOpen != widget.openState.isOpen) {
      controller.fling(velocity: isOpen ? 1 : -1);
    }
    super.didUpdateWidget(oldWidget);
  }

  void setOnTop(TabPath path) {
    if (!mounted) return;
    final isOnTop = path.pointsTo(context);
    if (onTop != isOnTop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          onTop = isOnTop;
        });
      });
    }
  }

  void toggleFrontLayer() => setState(() => onOpenChanged(!isOpen));

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    return ListenableProvider.value(
      value: _peakController,
      child: Column(
        //key: CheatersGlobalKey.of(context, 'backdrop'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            child: widget.bar,
          ),
          // Back layer
          SizeTransition(
            axisAlignment: -1.0,
            sizeFactor: CurvedAnimation(
              parent: controller,
              curve: Curves.easeInOut,
            ),
            child: SimpleSwitcher(child: widget.backLayer),
          ),
          // Front layer
          Expanded(
            child: VerticalFadeSwitcher(
              child: BigSheet(
                child: Scrim(
                  applied: isOpen,
                  child: wrappedFrontLayer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get wrappedFrontLayer => NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            widget.bar.applyPeakBehavior(_peakController, notification);
          }
          if (notification is ScrollEndNotification) {
            widget.bar.applyPeakSnapBehavior(_peakController, notification);
          }
          return false;
        },
        child: widget.frontLayer,
      );

  @override
  Widget build(BuildContext context) {
    final m = ModalRoute.of(context);
    final animation = m.animation;
    animation.addListener(() => print([m.isCurrent, animation.value]));
    return LayoutBuilder(builder: _buildStack);
  }

  @override
  void dispose() {
    /// TODO the backdrop is not disposed, but we only see
    /// builds from the
    print('disposing');
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<AnimationController>('controller', controller));
  }
}
