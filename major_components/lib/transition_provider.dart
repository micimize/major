import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

/// Container for exposing page route [animation] and [secondaryAnimation]
@immutable
class PageTransition {
  PageTransition(
    this.animation,
    this.secondaryAnimation,
  );

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;

  static final current = ScopedProvider<PageTransition>((_) => PageTransition(
        AlwaysStoppedAnimation(1),
        AlwaysStoppedAnimation(1),
      ));

  static withOverrides(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      current.overrideWithValue(PageTransition(animation, secondaryAnimation));

  static PageRouteBuilder route<T>({@required WidgetBuilder builder}) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: Duration(seconds: 1),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          _inPlacePageTransition(animation, secondaryAnimation);
          return ProviderScope(
            overrides: [
              current.overrideWithValue(
                PageTransition(animation, secondaryAnimation),
              )
            ],
            child: child,
          );
        },
      );
}

extension InPlaceAnimationHelper on ModalRoute {
  /// Helper for page transitions that don't need to differentiate between
  /// inbound animations and reversed outbound animations.
  ///
  /// If inbound, get [animation].
  /// If outbound, get the [secondaryAnimation] with a [ReversedAnimation] applied
  Animation<double> get inPlacePageTransition =>
      _inPlacePageTransition(animation, secondaryAnimation);
}

Animation<double> _inPlacePageTransition(
    Animation<double> inbound, Animation<double> outbound) {
  return AnimationMin(inbound, ReverseAnimation(outbound));
}

PageRouteBuilder inPlaceHandoffRoute<T>({
  @required WidgetBuilder builder,
  double handOff = 0.5,
}) =>
    PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: Duration(seconds: 1),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: _inPlacePageTransition(animation, secondaryAnimation),
            curve: Threshold(handOff),
          ),
          child: child,
        );
      },
    );
