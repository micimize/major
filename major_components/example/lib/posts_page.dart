import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:major_components/backdrop/backdrop.dart';
import 'package:major_components_example/back_nav.dart';
import 'package:major_components_example/data.dart';

class PostsPage extends ConsumerWidget {
  PostsPage({this.user});
  final User user;
  @override
  Widget build(BuildContext context, watch) {
    BackdropBarContent header(String text) => BackdropBarContent(
          title: BackdropTitle.fromText(text),
        );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        bottom: false,
        child: Backdrop(
          /// TODO this should be a riverpod thing I think
          openState: watch(BackdropOpenState.current),
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
      ),
    );
  }
}
