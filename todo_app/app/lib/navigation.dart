import 'package:flutter/material.dart';

class ControlledTabView extends StatelessWidget {
  const ControlledTabView({Key key, @required this.children}) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: TabBarView(
        children: children,
      ),
    );
  }
}

class NavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: TabBar(
        labelColor: Colors.pink,
        tabs: [
          Tab(child: Text('TODO')),
          Tab(child: Text('HISTORY')),
        ],
      ),
    );
  }
}
