import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:major_components/backdrop/backdrop.dart';
import 'package:major_components/backdrop/backdrop_state_provider.dart';
import 'package:major_components_example/data.dart';
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
  bool isOpen = false;

  @override
  void initState() {
    super.initState();

    backdropController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void onOpenChange(bool newOpen) {
    setState(() {
      isOpen = newOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    BackdropBarContent header(String text) => BackdropBarContent(
          title: BackdropTitle.fromText(text),
        );

    return ProviderScope(
      overrides: [
        BackdropOpenState.current.overrideWithValue(
          BackdropOpenState(
            isOpen: isOpen,
            onOpenChanged: onOpenChange,
            controller: backdropController,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Major Components',
        home: UsersPage(),
      ),
    );
  }
}
