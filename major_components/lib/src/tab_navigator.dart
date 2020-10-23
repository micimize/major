import 'package:flutter/material.dart';
import 'package:major_components/src/animations.dart';
import './transitions.dart';
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
  GlobalKey<NavigatorState> get navKey => tabNavigator.navStates[tabIndex];

  /// focused navigator
  NavigatorState get navState => navKey.currentState;

  /// focused observer
  RouteObserver<PageRoute> get observer => tabNavigator.observers[tabIndex];

  /// safely set the [tabNavigator] tab to this tab, then call [and]
  void setTab({VoidCallback and}) {
    if (tabIndex != tabNavigator.tabIndex && tabNavigator.mounted) {
      return tabNavigator.setTab(tabIndex, and: and);
    }
    //tabNavigator.previousTabIndex = tabNavigator.tabIndex;
    and();
  }
}

class TabNavigator extends StatefulWidget {
  TabNavigator({
    @required Iterable<String> tabs,
    @required this.builder,
    this.initialIndex = 0,
    this.transitionHandOff = 0.5,
    Key key,
  })  : tabs = tabs.map(_cleanTab).toList(),
        super(key: key);

  final List<String> tabs;
  final int initialIndex;

  /// At which point in the relative tab animation to hand off
  /// between tabs
  ///
  /// Used by animations down the tree to smoothly transition.
  final double transitionHandOff;

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
      result = tabState.navState.push<T>(route);
    });
    return result;
  }
}

class TabNavigatorState extends State<TabNavigator>
    with TickerProviderStateMixin<TabNavigator> {
  List<GlobalKey<NavigatorState>> navStates;
  List<RouteObserver<PageRoute>> observers;

  TabController controller;
  int get previousTabIndex => controller.previousIndex;
  int get tabIndex => controller.index;

  NavigatorState get currentNavigator => navStates[tabIndex].currentState;

  List<String> get tabNames => widget.tabs;
  int get tabCount => widget.tabs.length;

  List<TabNavFocus> get allTabData =>
      List.generate(tabCount, (index) => TabNavFocus._(this, index));

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

    observers = List.generate(tabCount, (i) => RouteObserver<PageRoute>());

    controller = TabController(
      initialIndex: widget.initialIndex,
      length: tabCount,
      vsync: this,
    );
  }

  void setTab(int newIndex, {VoidCallback and}) {
    controller.animateTo(tabIndex);
    setState(() {
      if (and != null) {
        and();
      }
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

extension TransitionHelpers on TabNavigatorState {
  /// At which point in the relative tab animation to hand off
  /// between tabs
  ///
  /// Used by animations down the tree to smoothly transition.
  double get transitionHandOff => widget.transitionHandOff;

  Animation<double> get relativeTransition => RelativeAnimation(
        parent: controller.animation,
        begin: previousTabIndex.toDouble(),
        end: tabIndex.toDouble(),
      );

  /// Where [relativeTransition].value has passed the [transitionHandOff]
  ///
  /// Will not function properly outside [AnimatedWidget]s, etc.
  bool get passedTransitionHandoff =>
      relativeTransition.value > transitionHandOff;

  /// [transitionHandOff]-thresholded tab index for use in [AnimatedWidget]s and the like.
  int get transitionTabIndex =>
      passedTransitionHandoff ? tabIndex : previousTabIndex;

  NavigatorState get transitionNavigator =>
      navStates[transitionTabIndex].currentState;
}

extension IsOnTop on ModalRoute {
  bool _isLogicallyOnTop(TabNavigatorState tabs) {
    if (!isCurrent) {
      return false;
    }

    /// If there is no tab navigator we assume it's topmost
    return tabs == null || (tabs.currentNavigator == navigator);
  }

  bool get isVisuallyOnTop {
    if (!isCurrent) {
      return false;
    }
    final tabs = TabNavigator.of(subtreeContext, isNullOk: true);

    /// If there is no tab navigator we assume it's topmost
    return tabs == null || (tabs.transitionNavigator == navigator);
  }

  Animation<double> get inPlacePageAndTabTransition {
    final tabs = TabNavigator.of(subtreeContext, isNullOk: true);
    final pageTransition = inPlacePageTransition;
    if (tabs == null) {
      return pageTransition;
    }
    final isEntering = _isLogicallyOnTop(tabs);
    var tabTransition = tabs.relativeTransition;
    if (!isEntering) {
      tabTransition = ReverseAnimation(tabTransition);
    }
    return AnimationMin(tabTransition, pageTransition);
  }
}
