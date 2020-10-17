import 'package:flutter/material.dart';
import 'package:major_components/backdrop/backdrop.dart';
import 'package:major_components/backdrop/backdrop_tabs.dart';
import 'package:major_components_example/data.dart';

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
    return MaterialApp(
      title: 'Major Components',
      home: Builder(
        builder: (conetxt) => Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Theme.of(context).primaryColor,
          body: SafeArea(
            bottom: false,
            child: Backdrop(
              /// TODO this should be a riverpod thing I think
              controller: BackdropController(
                isOpen: isOpen,
                onOpenChanged: onOpenChange,
                controller: backdropController,
              ),
              bar: BackdropBar(
                top: BackdropBarContent(
                  title: BackdropTitle.fromText('constant top'),
                ),
                back: header('back layer'),
                front: header('front layer'),
              ),
              backLayer: RaisedButton(onPressed: () {}, child: Text('wow')),
              frontLayer: User.infiniteList(context),
            ),
          ),
        ),
      ),
    );
  }
}
