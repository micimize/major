import 'package:flutter/material.dart';
import 'package:major_components/major_components.dart';
import 'package:major_components_example/back_nav.dart';
import 'package:major_components_example/data.dart';

class PostsPage extends StatelessWidget {
  PostsPage({this.user});
  final User user;
  @override
  Widget build(BuildContext context) {
    BackdropBarContent header(String text) => BackdropBarContent(
          title: BackdropTitle.fromText(text),
        );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).primaryColor,
      body: Backdrop(
        bar: BackdropBar(
          top: BackdropBarContent(
            title: BackdropTitle.fromText('constant top'),
          ),
          back: header('posts back layer'),
          front: header('posts front layer'),
        ),
        backLayer: BackNav(),
        frontLayer: User.infiniteList(context),
      ),
    );
  }
}
