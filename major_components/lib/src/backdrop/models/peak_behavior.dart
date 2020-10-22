import 'package:flutter/material.dart';

typedef WrapFrontLayerWithPeakBehavior<T extends Notification>
    = NotificationListener<T> Function(BuildContext context, Widget frontLayer);

/// Optionally add an affordance for revealing and hiding the top app bar
/// based on frontLayer [Notification]s.
///
/// [PeakTopBarOnDrag] is the only currently implemented peak behavior
abstract class BackdropBarPeakBehavior<T extends Notification> {
  /// Controller for peaking the top app bar
  @protected
  AnimationController get controller;

  /// The resolved animation for use in descendants, taking in to account
  /// the backdrop open state as well.
  Animation<double> get animation;

  /// Wrap the `frontLayer` in a [NotificationListener<T>] for applying the peak behavior
  NotificationListener<T> bindFrontLayer(
      BuildContext context, Widget frontLayer);

  static BackdropBarPeakBehavior of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PeakBehaviorModel>();
  }
}

/// Peak and hide the `top` bar content based on a drag down from the user on the `frontLayer`
class PeakTopBarOnDrag extends BackdropBarPeakBehavior<ScrollNotification> {
  PeakTopBarOnDrag(this.controller);
  final AnimationController controller;

  Animation<double> get animation => controller.view;

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

class PeakBehaviorModel extends InheritedNotifier<Animation<double>>
    implements BackdropBarPeakBehavior<Notification> {
  PeakBehaviorModel({
    Key key,
    @required Widget child,
    @required this.openAnimation,
    @required this.peakBehavior,
  }) : super(
          key: key,
          notifier: AnimationMax(openAnimation, peakBehavior.controller.view),
          child: child,
        );

  @protected
  final BackdropBarPeakBehavior peakBehavior;

  get controller => peakBehavior.controller;

  @protected
  final Animation<double> openAnimation;

  Animation<double> get animation => notifier;

  @override
  NotificationListener bindFrontLayer(c, f) =>
      peakBehavior.bindFrontLayer(c, f);

  @override
  bool updateShouldNotify(PeakBehaviorModel old) =>
      old.controller != controller ||
      old.peakBehavior.bindFrontLayer != peakBehavior.bindFrontLayer;
}
