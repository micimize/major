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

  static final current = ScopedProvider<PageTransition>(
    (_) => throw UnimplementedError(),
  );

  static withOverrides(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      current.overrideWithValue(PageTransition(animation, secondaryAnimation));

  static PageRouteBuilder route<T>({@required WidgetBuilder builder}) =>
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
