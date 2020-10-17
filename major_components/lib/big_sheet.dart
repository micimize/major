import 'package:flutter/material.dart';

/// A generic big [Material]. Useful for backdrops and bottom sheets.
class BigSheet extends StatelessWidget {
  const BigSheet({
    Key key,
    this.color,
    this.elevation = 12.0,
    this.child,
  }) : super(key: key);

  /// color of the [Material]. Defaults to `Theme.of(context).canvasColor`.
  final Color color;

  /// elevation of the [Material]. Defaults to `12.0`.
  final double elevation;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevation ?? 12.0,
      color: color ?? Theme.of(context).canvasColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: child ?? Container()),
        ],
      ),
    );
  }
}
