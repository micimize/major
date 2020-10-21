// ORIGINAL LICENSE:
// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:major_components/src/backdrop/big_sheet.dart';
import 'package:major_components/src/backdrop/scrim.dart';
import 'package:major_components/src/tab_navigator.dart';
import 'package:major_components/src/backdrop/_simple_switcher.dart';

import './backdrop_state_provider.dart';
import './backdrop_bar.dart';

import 'package:major_components/src/transitions.dart';

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
    final pageAnimation = ModalRoute.of(context).inPlacePageTransition;
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
      ),
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
