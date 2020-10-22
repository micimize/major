import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import './peak_behavior.dart';
import './open_state.dart';

class BackdropModelProvider extends StatelessWidget {
  const BackdropModelProvider({
    @required this.openState,
    this.peakBehavior,
    Key key,
    this.child,
  }) : super(key: key);

  final BackdropOpenStateReader openState;
  final BackdropBarPeakBehavior peakBehavior;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BackdropOpenModel(
      openState: openState,
      applyPeakBehavior: peakBehavior.bindFrontLayer,
      child: peakBehavior != null
          ? PeakBehaviorModel(
              openAnimation: openState.controller,
              peakBehavior: peakBehavior,
              child: child,
            )
          : child,
    );
  }
}
