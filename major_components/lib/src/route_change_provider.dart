import 'package:flutter/material.dart';
import 'package:major_components/src/tab_navigator.dart';

/// Subscribe to changes to the route context,
///
/// [subscribeToRouteChanges] and [unsubscribeFromRouteChanges]
/// MUST be called in [didChangeDependencies] and [dispose] respectively.
///
/// Also exposes [routeFromContext] and the [alwaysOnTopGlobalKey] utility.
mixin PageRouteChangeAware<T extends StatefulWidget> on State<T>
    implements RouteAware {
  RouteObserver<PageRoute<dynamic>> _observer;
  ModalRoute _route;
  TabNavigatorState _tabNav;

  /// Shortcut for getting the `ModalRoute.of(context)`
  /// we already  retrieved in order to subscribe to navigation
  ModalRoute get routeFromContext => _route;

  /// MUST be called in [didChangeDependencies]
  void subscribeToRouteChanges() {
    final nav = Navigator.of(context);
    _observer = nav.pageRouteObserver;
    if (_observer == null) {
      throw StateError(
        'Navigator $nav has no RouteObserver<PageRoute> in its observers! '
        'This is required for PageRouteChangeAware',
      );
    }
    _route = ModalRoute.of(context);
    _observer.subscribe(this, _route);
    _tabNav = TabNavigator.of(context, isNullOk: true);
  }

  /// MUST be called in [dispose]
  void unsubscribeFromRouteChanges() => _observer?.unsubscribe(this);

  /// Creates a [GlobalObjectKey] when the [routeFromContext] [IsOnTop],
  /// otherwise uses a regular [ObjectKey].
  ///
  /// Is only exposed from [RouteChangeObserver] because
  /// the containing widget might not get rebuilt without it.
  ///
  /// I'm not entirely sure we can get away with this –
  /// rebuilding [GlobalKey]s in render is supposed to be bad,
  /// but idk if that applies to [GlobalObjectKey]s.
  ///
  /// Anyhow, is is possible that we should actually be using the [CheatersIndexedStack] approach.
  /// [CheatersIndexedStack]: https://gist.github.com/micimize/5191af05191c027713a9cd1def3528db
  Key alwaysOnTopGlobalKey(
    BuildContext context,
    Object label, {
    bool when = true,
  }) {
    return _route.isVisuallyOnTop && when
        ? GlobalObjectKey(label)
        : ObjectKey(label);
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

extension GetPageRouteObserverFromNav on Navigator {
  RouteObserver<PageRoute> get pageRouteObserver {
    final obs = observers.whereType<RouteObserver<PageRoute>>();
    if (obs.isEmpty) {
      return null;
    }
    return obs.first;
  }
}

extension GetPageRouteObserverFromNavState on NavigatorState {
  RouteObserver<PageRoute> get pageRouteObserver => widget.pageRouteObserver;
}

/// Provide a simple `RouteObserver<PageRoute<dynamic>>` for injection as a navigator observable
///
/// See also: [TabNavigatorState.observers]
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
