// ORIGINAL LICENSE:
// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:major_components/major_components.dart';

import 'package:major_components/src/backdrop/big_sheet.dart';
import 'package:major_components/src/backdrop/scrim.dart';
import 'package:major_components/src/backdrop/_simple_switcher.dart';
import 'package:major_components/src/tab_navigator.dart';

import './backdrop_state_provider.dart';
import './backdrop_bar.dart';

import 'package:major_components/src/transitions.dart';

import 'package:major_components/src/cheaters_global_key.dart';

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
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin, RouteChangeObserver<Backdrop> {
  // TODO It's awkward to have both controller-driven and in-place duration-driven animations
  // TODO Maybe we should just replace the controller with top-level durations and curves?

  bool get isOpen => widget.openState.isOpen;
  AnimationController get controller => widget.openState.controller;
  ValueChanged<bool> get onOpenChanged => widget.openState.onOpenChanged;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isOpen) {
        controller.value = 0.0;
      }
    });
  }

  @override
  void didUpdateWidget(oldWidget) {
    if (oldWidget.openState.isOpen != widget.openState.isOpen) {
      controller.fling(velocity: isOpen ? 1 : -1);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscribeToRouteChanges();
  }

  @override
  void dispose() {
    unsubscribeFromRouteChanges();
    super.dispose();
  }

  void toggleFrontLayer() => setState(() => onOpenChanged(!isOpen));

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    final pageAnimation = routeFromContext.inPlacePageTransition;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: alwaysOnTopGlobalKey(
            context,
            'major_components.BackdropBar',
            when: pageAnimation.value >= 0.5,
          ),
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
          child: SlideVerticallyBetweenPages(
            pageAnimation: pageAnimation,
            child: BigSheet(
              child: Scrim(
                applied: isOpen,
                child: FadeBetweenPages(
                  pageAnimation: pageAnimation,
                  child: wrappedFrontLayer,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget get wrappedFrontLayer {
    if (widget.openState.peakBehavior != null) {
      return widget.frontLayer;
    }
    return widget.openState.peakBehavior.bindFrontLayer(
      context,
      widget.frontLayer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildStack);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<AnimationController>('controller', controller));
  }
}
