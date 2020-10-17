import 'package:flutter/material.dart';
import './pointless.dart';

typedef OnPathChange = void Function(TabPath currentPath);

@immutable
class TabPath {
  const TabPath(this.name, this.index, this.route);
  final String name;
  final int index;
  final PageRoute route;

  bool pointsTo(BuildContext context) {
    final focus = TabNavigator.focusOf(context);
    return focus.tabIndex == index && route == ModalRoute.of(context);
  }

  @override
  String toString() => 'TabPath($name, $index, ${route?.settings?.name})';
}

/// Wrapper around [NavigatorState] providing helpers
class TabNavFocus {
  TabNavFocus._(this.tabNavigator, this.tabIndex);

  /// Focused tab index
  final int tabIndex;

  /// Entire backing state
  final TabNavigatorState tabNavigator;

  /// Whether [tabIndex] is the current tab
  bool get isCurrent => tabNavigator.tabIndex == tabIndex;

  /// focused navigator
  NavigatorState get state => tabNavigator.navStates[tabIndex].currentState;

  RouteObserver<PageRoute> get observer => tabNavigator.observers[tabIndex];

  /// safely set the [tabNavigator] tab to this tab, then call [and]
  void setTab({VoidCallback and}) {
    if (tabIndex != tabNavigator.tabIndex && tabNavigator.mounted) {
      tabNavigator.setTab(tabIndex, and: and);
    } else {
      tabNavigator.previousTabIndex = tabNavigator.tabIndex;
      and();
    }
  }
}

class TabNavigator extends StatefulWidget {
  TabNavigator({
    @required Iterable<String> tabs,
    @required this.builder,
    Key key,
  })  : tabs = tabs.map(_cleanTab).toList(),
        super(key: key);

  final List<String> tabs;
  final Widget Function(BuildContext context, TabNavigatorState tabNavigator)
      builder;

  @override
  TabNavigatorState createState() => TabNavigatorState();

  static String _cleanTab(String t) => t.trim().toUpperCase();

  static TabNavigatorState of(
    BuildContext context, {
    bool isNullOk = false,
  }) {
    assert(isNullOk != null);
    assert(context != null);
    final TabNavigatorState result =
        context.findAncestorStateOfType<TabNavigatorState>();
    if (isNullOk || result != null) {
      return result;
    }
    throw FlutterError(
      'TabNavigator.of() called with a context that does not contain a TabNavigator .\n',
    );
  }

  /// [TabNavFocus] for either [tab], or [forCurrentTab], or for that of the [context]
  static TabNavFocus focusOf(
    BuildContext context, {
    String tab,
    bool forCurrentTab = false,
  }) {
    final navState = of(context);
    int tabIndex;
    if (tab != null || forCurrentTab) {
      tabIndex = tab != null
          ? navState.widget.tabs.indexOf(_cleanTab(tab))
          : navState.tabIndex;
    } else {
      tabIndex = navState.navStates
          .map((key) => key.currentState)
          .toList()
          .indexOf(Navigator.of(context));
    }
    return TabNavFocus._(navState, tabIndex);
  }

  static Future<T> navigateTo<T extends Object>(
    BuildContext context, {
    String tab,
    @required ModalRoute<T> route,
  }) {
    final tabState = focusOf(context, tab: tab, forCurrentTab: tab == null);
    // TODO janky AF, but realized we want return values from navigateTo
    Future<T> result;
    tabState.setTab(and: () {
      result = tabState.state.push<T>(route);
    });
    return result;
  }

  /// subscribe to navigation events and return an unsubscribe callbakc
  static VoidCallback subscribe(
    BuildContext context,
    void Function(TabPath currentPath) onChange,
  ) {
    final focus = focusOf(context);
    focus.tabNavigator._subscribers.add(onChange);
    return () => focus.tabNavigator._subscribers.remove(onChange);
  }
}

class TabNavigatorState extends State<TabNavigator>
    with TickerProviderStateMixin {
  List<GlobalKey<NavigatorState>> navStates;
  List<TabObserver> observers;
  List<PageRoute> topRoutes;

  final Set<OnPathChange> _subscribers = {};

  TabPath get currentPath =>
      TabPath(tabNames[tabIndex], tabIndex, topRoutes[tabIndex]);

  void _setPath(int index, PageRoute route) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          topRoutes[index] = route;
          notifyPathListeners();
        });
      });

  void notifyPathListeners() {
    final path = currentPath;
    for (final callback in _subscribers) {
      callback(path);
    }
  }

  int previousTabIndex = 0;

  TabController controller;

  int tabIndex = 0;

  NavigatorState get currentNavigator => navStates[tabIndex].currentState;

  List<String> get tabNames => widget.tabs;

  @override
  void initState() {
    super.initState();

    navStates = widget.tabs
        .map(
          withIndex(
            (tabName, i) => GlobalKey<NavigatorState>(
              debugLabel: 'TabNav($i, $tabName)',
            ),
          ),
        )
        .toList();

    observers = List.generate(
      widget.tabs.length,
      (i) => TabObserver(
        onChange: (route) => _setPath(i, route),
      ),
    );

    topRoutes = List.generate(widget.tabs.length, (i) => null);

    controller = TabController(
      initialIndex: 0,
      length: widget.tabs.length,
      vsync: this,
    );
  }

  void setTab(int newIndex, {VoidCallback and}) {
    setState(() {
      previousTabIndex = tabIndex;
      tabIndex = newIndex;
      if (and != null) {
        and();
      }
      if (controller.index != tabIndex) {
        controller.animateTo(tabIndex);
      }
      //notifyPathListeners();
    });
  }

  ///  Pop the given tab [index] until it is back to its root
  void popToTop([int index]) => navStates[index ?? tabIndex]
      .currentState
      .popUntil((route) => route.isFirst);

  /// if tab selected, [popToTop] and set `previousTabIndex = tabIndex`. Otherwise, navigate to [newIndex]
  void onTapTab(int newIndex) {
    // double tap
    if (newIndex == tabIndex) {
      setState(() => previousTabIndex = tabIndex);
      popToTop();
    } else if (mounted) {
      setTab(newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, this);
  }
}

class TabObserver extends RouteObserver<PageRoute<dynamic>> {
  TabObserver({@required this.onChange});

  final void Function(PageRoute<dynamic> route) onChange;

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      onChange(route);
    }
  }

  @override
  void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      onChange(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      onChange(previousRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didRemove(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      onChange(previousRoute);
    }
  }
}

/*
class TabRouteProvider extends StatefulWidget {
  @override
  _TabRouteProviderState createState() => _TabRouteProviderState();
}

class _TabRouteProviderState extends State<TabRouteProvider> with RouteAware {
  RouteObserver<PageRoute> routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CurrentTab>();
    return Container();
  }
}
*/
