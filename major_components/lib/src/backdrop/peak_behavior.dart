import 'package:flutter/material.dart';

/// Optionally add an affordance for revealing and hiding the top app bar
/// based on frontLayer [Notification]s.
///
/// [PeakTopBarOnDrag] is the only currently implemented peak behavior
abstract class BackdropBarPeakBehavior<T extends Notification> {
  /// Controller for peaking the top app bar
  AnimationController controller;

  /// Wrap the `frontLayer` in a [NotificationListener<T>] for applying the peak behavior
  NotificationListener<T> bindFrontLayer(
      BuildContext context, Widget frontLayer);
}

/// Peak and hide the `top` bar content based on a drag down from the user on the `frontLayer`
class PeakTopBarOnDrag extends BackdropBarPeakBehavior<ScrollNotification> {
  PeakTopBarOnDrag(this.controller);
  final AnimationController controller;

  /// TODO old docstring: Returns true to cancel bubbling
  void call(
    ScrollUpdateNotification notification,
  ) {
    if (notification.dragDetails == null) {
      return snap(notification);
    }

    controller.value += notification.dragDetails.primaryDelta / 56;
  }

  void snap(ScrollNotification notification) async {
    if (controller.isAnimating ||
        controller.status == AnimationStatus.completed) return;
    controller.fling(velocity: controller.value > 0.5 ? 1.0 : -1.0);
  }

  @override
  bindFrontLayer(BuildContext context, Widget frontLayer) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            this(notification);
          }
          if (notification is ScrollEndNotification) {
            snap(notification);
          }
          return false;
        },
        child: frontLayer,
      );
}
