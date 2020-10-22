// ORIGINAL LICENSE:
// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:major_components/src/backdrop/big_sheet.dart';
import 'package:major_components/src/backdrop/models/open_state.dart';
import 'package:major_components/src/backdrop/scrim.dart';
import 'package:major_components/src/backdrop/_simple_switcher.dart';
import 'package:major_components/src/route_change_provider.dart';
import 'package:major_components/src/transitions.dart';

import './backdrop_bar.dart';

class Backdrop extends StatefulWidget {
  const Backdrop({
    this.bar,
    this.frontHeading,
    this.frontLayer,
    this.backLayer,
    Key key,
  }) : super(key: key);

  ///
  final BackdropBar bar;

  final Widget backLayer;
  final Widget frontLayer;

  final Widget frontHeading;

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin, RouteChangeObserver<Backdrop> {
  // TODO It's awkward to have both controller-driven and in-place duration-driven animations
  // TODO Maybe we should just replace the controller with top-level durations and curves?

  BackdropOpenModel openState;

  bool get isOpen => openState.isOpen;
  AnimationController get controller => openState.controller;
  ValueChanged<bool> get onOpenChanged => openState.onOpenChanged;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscribeToRouteChanges();
    openState = BackdropOpenState.of(context);
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
    if (!openState.isPeakable) {
      return widget.frontLayer;
    }
    return openState.applyPeakBehavior(
      context,
      widget.frontLayer,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildStack);
  }
}
