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
            title: BackdropPillTabsFromTabNavigator().withTitlePadding,
          ),
          back: header('posts back layer'),
          front: header('posts front layer'),
        ),
        backLayer: BackNav(),
        frontLayer: PostList(),
      ),
    );
  }
}

class PostList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: posts.length,
        itemBuilder: (c, i) {
          final p = posts[i];
          return ListTile(
            isThreeLine: true,
            leading: Icon(p.icon),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title),
                Text(
                  p.likes.toString(),
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
            subtitle: Text(
              p.description,
              maxLines: 2,
            ),
          );
        });
  }
}
