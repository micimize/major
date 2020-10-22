import 'package:flutter/material.dart';
import 'package:major_components/major_components.dart';
import 'package:meta/meta.dart';
import 'package:major_components/src/backdrop/models/peak_behavior.dart';

/// Container for backdrop open state state
abstract class BackdropOpenStateReader {
  /// Whether the backdrop is expanded, semantically
  bool get isOpen;

  /// Callback to trigger when the backdrop wants to change the open state
  ValueChanged<bool> get onOpenChanged;

  /// Attempt to toggle the open state with [onOpenChanged]
  void toggleOpen() => onOpenChanged(!isOpen);

  /// Controller for main backdrop open/closed animation
  AnimationController get controller;

  /// Controller for main backdrop open/closed animation
  Animation<double> get animation => controller.view;

  static BackdropOpenStateReader of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BackdropOpenModel>();
  }
}

class BackdropOpenState implements BackdropOpenStateReader {
  BackdropOpenState({
    @required this.isOpen,
    @required this.controller,
    @required this.onOpenChanged,
  }) {
    if (!controller.isAnimating) {
      controller.value = isOpen ? 1.0 : 0.0;
    }
  }

  /// Whether the backdrop is expanded, semantically
  bool isOpen;

  void fling(newOpen) {
    isOpen = newOpen;
    controller.fling(velocity: isOpen ? 1 : -1);
  }

  /// Callback to trigger when the backdrop wants to change the open state
  ValueChanged<bool> onOpenChanged;

  /// Attempt to toggle the open state with [onOpenChanged]
  void toggleOpen() => onOpenChanged(!isOpen);

  /// Controller for main backdrop open/closed animation
  AnimationController controller;

  /// Controller for main backdrop open/closed animation
  Animation<double> get animation => controller.view;

  static BackdropOpenStateReader of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BackdropOpenModel>();
  }
}

/// Internal model
class BackdropOpenModel extends InheritedNotifier<AnimationController>
    implements BackdropOpenStateReader {
  BackdropOpenModel({
    Key key,
    @required Widget child,
    @required this.openState,
    this.applyPeakBehavior,
  }) : super(key: key, notifier: openState.controller, child: child);

  @protected
  final BackdropOpenState openState;

  /// Whether the backdrop is expanded, semantically
  bool get isOpen => openState.isOpen;

  /// Callback to trigger when the backdrop wants to change the open state
  ValueChanged<bool> get onOpenChanged => openState.onOpenChanged;

  /// Attempt to toggle the open state with [onOpenChanged]
  void toggleOpen() => onOpenChanged(!isOpen);

  AnimationController get controller => openState.controller;

  /// Controller for main backdrop open/closed animation
  Animation<double> get animation => controller.view;

  final WrapFrontLayerWithPeakBehavior applyPeakBehavior;

  bool get isPeakable => applyPeakBehavior != null;

  @override
  bool updateShouldNotify(BackdropOpenModel old) =>
      old.isOpen != isOpen ||
      old.onOpenChanged != onOpenChanged ||
      old.controller != controller;

  /// Get the peak behavior controller and listen to to it with the context.
  ///
  /// We do this this way so that the [Backdrop] at large doesn't need to
  /// listen to the peak behavior, but it is still easily and safely accessible
  /// from the [BackdropBar]
  Animation<double> resolvePeakAnimationOf(BuildContext context) {
    if (isPeakable) {
      return BackdropBarPeakBehavior.of(context).animation;
    }
    return openState.controller.view;
  }
}
