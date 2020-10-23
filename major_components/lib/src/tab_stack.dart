import 'package:flutter/material.dart';
import 'package:major_components/major_components.dart';
import 'package:functional/functional.dart';

typedef TabStackItemBuilder = Widget Function(
  BuildContext context,
  TabNavFocus data,
);

class TabStack extends AnimatedWidget {
  TabStack({
    Key key,
    @required this.tabNavigator,
    @required this.itemBuilder,
  }) : super(key: key, listenable: tabNavigator.controller.animation);

  final TabNavigatorState tabNavigator;
  final TabStackItemBuilder itemBuilder;

  static TabStackItemBuilder inPlaceNavBuilder(List<WidgetBuilder> pages) =>
      (context, tab) => Navigator(
            key: tab.navKey,
            observers: [tab.observer],
            onGenerateRoute: (route) {
              return InPlaceHandoffPageRoute<Object>(
                settings: route,
                maintainState: true,
                pageBuilder: ignoreAnimations(pages[tab.tabIndex]),
              );
            },
          );

  @override
  Widget build(BuildContext context) {
    final buildItem = itemBuilder % context;
    return IndexedStack(
      index: tabNavigator.transitionTabIndex,
      children: tabNavigator.allTabData.map(buildItem).toList(),
    );
  }
}
