// TODO configuration for coupling a global handoff point with the handoff-like transitions
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

extension InPlaceAnimationHelper on ModalRoute {
  /// Helper for page transitions that don't need to differentiate between
  /// inbound animations and reversed outbound animations.
  ///
  /// If inbound, get [animation].
  /// If outbound, get the [secondaryAnimation] with a [ReversedAnimation] applied
  ///
  /// **Does not account for tab transitions**, for which you'll want to use
  /// [inPlacePageAndTabTransition]
  Animation<double> get inPlacePageTransition =>
      _inPlacePageTransition(animation, secondaryAnimation);
}

Animation<double> _inPlacePageTransition(
    Animation<double> inbound, Animation<double> outbound) {
  return AnimationMin(inbound, ReverseAnimation(outbound));
}

RoutePageBuilder ignoreAnimations(WidgetBuilder builder) =>
    (context, anime, secondAnime) => builder(context);

class InPlaceHandoffPageRoute<T> extends PageRouteBuilder<T> {
  /// Creates a route that fades abruptly at the [handOff] point with a [Threshold]
  InPlaceHandoffPageRoute({
    RouteSettings settings,
    @required RoutePageBuilder pageBuilder,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Duration reverseTransitionDuration = const Duration(milliseconds: 300),
    bool maintainState = true,
    bool fullscreenDialog = false,
    this.handOff = 0.5,
  }) : super(
          settings: settings,
          pageBuilder: pageBuilder,
          fullscreenDialog: fullscreenDialog,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: _inPlacePageTransition(animation, secondaryAnimation),
                curve: Threshold(handOff),
              ),
              child: child,
            );
          },
          transitionDuration: transitionDuration,
          reverseTransitionDuration: reverseTransitionDuration,
        );

  /// The point in the animation at which to switch routes
  final double handOff;
}

/// Vertically slide the child depending on [ModalRoute.inPlacePageTransition]
class SlideVerticallyBetweenPages extends StatelessWidget {
  SlideVerticallyBetweenPages({
    @required this.child,
    this.curve = Curves.easeOutQuad,
    this.reverseCurve = Curves.easeOut,
    this.bottom = const Offset(0, 0.5),
    this.pageAnimation,
  });

  final Widget child;

  final Curve curve;
  final Curve reverseCurve;

  /// The offset at which the outbound child ends and inbound child starts
  final Offset bottom;

  /// The current page transition animation.
  ///
  /// Defaults to [ModalRoute.inPlacePageTransition],
  /// but is made an option so contexts with multiple transitions
  /// can make a single call.
  final Animation<double> pageAnimation;

  @override
  Widget build(BuildContext context) {
    final animation =
        pageAnimation ?? ModalRoute.of(context).inPlacePageTransition;
    return SlideTransition(
      position: Tween(
        begin: bottom,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: reverseCurve,
        ),
      ),
      child: child,
    );
  }
}

/// Fade the child depending on [ModalRoute.inPlacePageTransition]
class FadeBetweenPages extends StatelessWidget {
  FadeBetweenPages({
    @required this.child,
    this.curve = defaultCurve,
    this.reverseCurve = defaultReverseCurve,
    this.pageAnimation,
  });

  final Widget child;

  final Curve curve;
  final Curve reverseCurve;

  /// The current page transition animation.
  ///
  /// Defaults to [ModalRoute.inPlacePageTransition],
  /// but is made an option so contexts with multiple transitions
  /// can make a single call.
  final Animation<double> pageAnimation;

  static const defaultCurve = Interval(0.4, 1.0, curve: Curves.easeIn);
  static const defaultReverseCurve = Interval(0.4, 1.0, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final animation =
        pageAnimation ?? ModalRoute.of(context).inPlacePageTransition;
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: reverseCurve,
      ),
      child: child,
    );
  }
}
