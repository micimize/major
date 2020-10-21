import 'package:flutter/material.dart' hide TabBar;
import './_flutter_tabs_with_custom_inkwell.dart';

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
}
