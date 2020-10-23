import 'package:flutter/material.dart' hide TabBar;
import 'package:major_components/src/tab_navigator.dart';
import './_flutter_tabs_with_custom_inkwell.dart';

/// Crane-like backdrop tabs.
///
/// Can be constructed from [fromTabNavigator]
///
class BackdropPillTabs extends StatelessWidget {
  BackdropPillTabs({
    Key key,
    @required this.tabs,
    this.controller,
    this.indicatorColor,
    this.indicatorWeight = 2,
    this.indicatorBorderRadius,
    this.onTap,
  }) : super(key: key);

  static const defaultLabelPadding = EdgeInsets.only(top: 8, bottom: 8);

  final TabController controller;
  final BorderRadius indicatorBorderRadius;
  final Color indicatorColor;
  final double indicatorWeight;
  final ValueChanged<int> onTap;
  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = indicatorBorderRadius ?? BorderRadius.circular(18.0);
    final color = indicatorColor ?? theme.colorScheme.onPrimary;

    return TabBar(
      controller: controller,
      indicator: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: color,
            width: indicatorWeight,
          ),
        ),
      ),
      indicatorWeight: 0.0, // disable bottom padding
      onTap: onTap,
      inkWellBorderRadius: radius,
      tabs: tabs,
      labelPadding: defaultLabelPadding,
      labelStyle: theme.textTheme.button,
    );
  }

  Widget get withTitlePadding => _withTitlePadding(this);
}

class BackdropPillTabsFromTabNavigator extends StatelessWidget {
  BackdropPillTabsFromTabNavigator({
    Key key,
    this.tabNavigator,
    this.indicatorColor,
    this.indicatorWeight = 2,
    this.indicatorBorderRadius,
    this.onTap,
  }) : super(key: key);

  /// Defaults to `TabNavigator.of(context)`
  final TabNavigatorState tabNavigator;
  final BorderRadius indicatorBorderRadius;
  final Color indicatorColor;
  final double indicatorWeight;
  final ValueChanged<int> onTap;

  ValueChanged<int> wrapTap(ValueChanged<int> navTap) => onTap == null
      ? navTap
      : (i) {
          onTap(i);
          return tabNavigator.onTapTab(i);
        };

  @override
  Widget build(BuildContext context) {
    final tabNav = tabNavigator ?? TabNavigator.of(context);
    return BackdropPillTabs(
      tabs: tabNav.tabNames.map((n) => Text(n)).toList(),
      onTap: wrapTap(tabNav.onTapTab),
      controller: tabNav.controller,
      indicatorBorderRadius: indicatorBorderRadius,
      indicatorColor: indicatorColor,
      indicatorWeight: indicatorWeight,
    );
  }

  Widget get withTitlePadding => _withTitlePadding(this);
}

Widget _withTitlePadding(Widget w) => Container(
      padding: EdgeInsets.only(top: 6),
      height: 40,
      child: w,
    );
