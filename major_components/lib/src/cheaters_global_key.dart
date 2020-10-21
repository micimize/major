import 'package:flutter/material.dart';
import 'package:major_components/src/pointless.dart';

class CheatersGlobalKey extends InheritedWidget {
  CheatersGlobalKey._({
    this.cheatersKeys = const {},
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  final Map<String, Key> cheatersKeys;

  @override
  bool updateShouldNotify(CheatersGlobalKey oldWidget) {
    return cheatersKeys != oldWidget.cheatersKeys;
  }

  static Key of(
    BuildContext context,
    String label,
  ) {
    assert(context != null);

    final route = ModalRoute.of(context);

    // only the current route cans safely render a GlobalKey
    if (!route.isCurrent) {
      return Key(label);
    }

    return GlobalObjectKey(label);
  }
}

class CheatersIndexedStack extends StatelessWidget {
  CheatersIndexedStack({
    Key key,
    @required this.index,
    @required this.cheatersKeys,
    @required this.children,
    List<String> contextLabels,
  })  : this.contextLabels = contextLabels ??
            List<String>.generate(
              children.length,
              (i) => 'cheater.index=$i',
            ),
        super(key: key) {
    assert(this.contextLabels.length == children.length);
  }

  final Set<String> cheatersKeys;
  final List<String> contextLabels;
  final List<Widget> children;
  final int index;

  Map<String, Key> keysFor(int childIndex) {
    return index == childIndex
        ? Map.fromEntries(cheatersKeys.map(
            (label) => MapEntry(
              label,
              _CheatersGlobalKey(label, contextLabels[childIndex]),
            ),
          ))
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: index,
      children: children.map(withIndex((child, childIndex) {
        return CheatersGlobalKey._(
          // should change every tab switch
          cheatersKeys: keysFor(childIndex),
          child: child,
        );
      })).toList(),
    );
  }
}

class _CheatersGlobalKey extends GlobalObjectKey {
  const _CheatersGlobalKey(String globalLabel, this.contextLabel)
      : super(globalLabel);

  final String contextLabel;

  @override
  String toString() {
    return '[_CheatersGlobalKey#$hashCode value=$value, context=$contextLabel]';
  }
}
