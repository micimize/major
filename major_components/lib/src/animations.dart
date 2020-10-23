import 'package:flutter/material.dart';

/// Bound an animation between `0.0` and `1.0`
/// based on [begin] and [end] and projects its direction/status as needed
class RelativeAnimation extends Animation<double>
    with
        AnimationLazyListenerMixin,
        AnimationWithParentMixin<double>,
        AnimationLocalStatusListenersMixin {
  /// Creates a curved animation.
  ///
  /// The parent and curve arguments must not be null.
  RelativeAnimation({
    @required this.parent,
    @required this.begin,
    @required this.end,
  })  : assert(parent != null),
        assert(begin != null),
        assert(end != null),
        _projectStatus = (end < begin) ? _reverseStatus : _noop;

  /// if we should reverse, we project through a status reversal

  /// The animation to which this animation applies a curve.
  @override
  final Animation<double> parent;

  final double begin;
  final double end;

  final AnimationStatus Function(AnimationStatus status) _projectStatus;

  double get value {
    final distanceToEnd = (end - begin).abs();
    if (distanceToEnd == 0.0) {
      return 1.0; // if we haven't moved we're in-place
    }
    final traversedDistanceFromBegin = (parent.value - begin).abs();
    // once we have traversed a distance equal to the distance to the current tab,
    // we have gotten there, and the value will be 1.
    return traversedDistanceFromBegin / distanceToEnd;
  }

  @override
  void addListener(VoidCallback listener) {
    didRegisterListener();
    parent.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    parent.removeListener(listener);
    didUnregisterListener();
  }

  @override
  void didStartListening() {
    parent.addStatusListener(_statusChangeHandler);
  }

  @override
  void didStopListening() {
    parent.removeStatusListener(_statusChangeHandler);
  }

  void _statusChangeHandler(AnimationStatus status) {
    notifyStatusListeners(_projectStatus(status));
  }

  @override
  AnimationStatus get status => _projectStatus(parent.status);

  static AnimationStatus _noop(AnimationStatus status) => status;

  static AnimationStatus _reverseStatus(AnimationStatus status) {
    assert(status != null);
    switch (status) {
      case AnimationStatus.forward:
        return AnimationStatus.reverse;
      case AnimationStatus.reverse:
        return AnimationStatus.forward;
      case AnimationStatus.completed:
        return AnimationStatus.dismissed;
      case AnimationStatus.dismissed:
        return AnimationStatus.completed;
    }
    return status;
  }
}
