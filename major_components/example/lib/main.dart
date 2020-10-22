import 'package:flutter/material.dart';
import 'package:major_components/major_components.dart';

import './users_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TickerProviderStateMixin<MyHomePage> {
  AnimationController backdropController;
  AnimationController peakController;

  BackdropOpenState openState;
  BackdropBarPeakBehavior peakBehavior;

  @override
  void initState() {
    super.initState();
    openState = BackdropOpenState(
      isOpen: false,
      onOpenChanged: onOpenChange,
      controller: AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
    peakBehavior = PeakTopBarOnDrag(
      AnimationController(vsync: this)..value = 1,
    );
  }

  void onOpenChange(bool newOpen) => setState(() => openState.fling(newOpen));

  @override
  Widget build(BuildContext context) {
    return BackdropModelProvider(
      openState: openState,
      peakBehavior: peakBehavior,
      child: RouteChangeProvider(
        builder: (context, observer) => MaterialApp(
          title: 'Major Components',
          navigatorObservers: [observer],
          home: UsersPage(),
        ),
      ),
    );
  }
}
