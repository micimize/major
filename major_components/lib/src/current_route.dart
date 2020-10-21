import 'package:flutter/material.dart';
import 'package:major_components/src/tab_navigator.dart';

/// Subscribe to changes to the route context,
///
/// [subscribeToRouteChanges] and [unsubscribeFromRouteChanges]
/// MUST be called in [didChangeDependencies] and [dispose] respectively.
///
/// Also exposes [routeFromContext] and the [alwaysOnTopGlobalKey] utility.
mixin RouteChangeObserver<T extends StatefulWidget> on State<T>
    implements RouteAware {
  RouteObserver<PageRoute<dynamic>> _observer;
  ModalRoute _route;

  /// Shortcut for getting the `ModalRoute.of(context)`
  /// we already  retrieved in order to subscribe to navigation
  ModalRoute get routeFromContext => _route;

  /// MUST be called in [didChangeDependencies]
  void subscribeToRouteChanges() {
    _observer = RouteChangeProvider.of(context).observer;
    _route = ModalRoute.of(context);
    _observer.subscribe(this, _route);
  }

  /// MUST be called in [dispose]
  void unsubscribeFromRouteChanges() => _observer?.unsubscribe(this);

  /// Creates a [GlobalObjectKey] when the [routeFromContext] [IsOnTop],
  /// otherwise uses a regular [ObjectKey].
  ///
  /// Is only exposed from [RouteChangeObserver] because
  /// the containing widget might not get rebuilt without it.
  Key alwaysOnTopGlobalKey(
    BuildContext context,
    Object label, {
    bool when = true,
  }) {
    return _route.isOnTop && when ? GlobalObjectKey(label) : ObjectKey(label);
  }

  void _setCurrent(bool val) => setState(() => val);

  @override
  void didPopNext() => _setCurrent(true);
  @override
  void didPush() => _setCurrent(true);

  @override
  void didPop() => _setCurrent(false);
  @override
  void didPushNext() => _setCurrent(false);
}

class RouteChangeProvider extends StatefulWidget {
  RouteChangeProvider({
    @required this.builder,
    Key key,
  }) : super(key: key);

  final Widget Function(
      BuildContext context, RouteObserver<PageRoute<dynamic>> observer) builder;

  static RouteChangeProviderState of(
    BuildContext context,
  ) =>
      context.findAncestorStateOfType<RouteChangeProviderState>();

  @override
  RouteChangeProviderState createState() => RouteChangeProviderState();
}

class RouteChangeProviderState extends State<RouteChangeProvider> {
  final RouteObserver<PageRoute<dynamic>> observer =
      RouteObserver<PageRoute<dynamic>>();

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, observer);
  }
}

/*
extension IsOnTop on BuildContext {
  bool get routeIsOnTop {
    final route = CurrentRoute.of(this).route;
    final contextRoute = ModalRoute.of(this);
    if (!contextRoute.routeIsCurrent || contextRoute != route) {
      return false;
    }

    final tabs = TabNavigator.of(this, isNullOk: true);

    /// If there is no tab navigator we assume it's topmost
    return tabs == null || tabs.currentNavigator == contextRoute.navigator;
  }
}

*/
