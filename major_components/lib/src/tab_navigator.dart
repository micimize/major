import 'package:flutter/material.dart';
import './pointless.dart';

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

  /// [TabNavFocus] for either [tab], or for [currentTab], or for that of the [context]
  static TabNavFocus focusOf(
    BuildContext context, {
    String tab,
    bool currentTab = false,
  }) {
    final navState = of(context);
    int tabIndex;
    if (tab != null || currentTab) {
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
    final tabState = focusOf(context, tab: tab, currentTab: tab == null);
    // TODO janky AF, but realized we want return values from navigateTo
    Future<T> result;
    tabState.setTab(and: () {
      result = tabState.state.push<T>(route);
    });
    return result;
  }
}

class TabNavigatorState extends State<TabNavigator>
    with TickerProviderStateMixin {
  List<GlobalKey<NavigatorState>> navStates;
  List<PageRoute> topRoutes;

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

extension IsOnTop on ModalRoute {
  bool get isOnTop {
    if (!isCurrent) {
      return false;
    }
    final tabs = TabNavigator.of(subtreeContext, isNullOk: true);

    /// If there is no tab navigator we assume it's topmost
    return tabs == null || tabs.currentNavigator == navigator;
  }
}
