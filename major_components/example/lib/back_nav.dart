import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:major_components/major_components.dart';
import 'package:major_components_example/data.dart';
import 'package:major_components_example/posts_page.dart';
import 'package:major_components_example/users_page.dart';

class BackNav extends ConsumerWidget {
  BackNav();

  @override
  Widget build(BuildContext context, watch) {
    VoidCallback navigateTo(String name, WidgetBuilder page) =>
        () => Navigator.push(
              context,
              inPlaceHandoffRoute(
                  builder: page, settings: RouteSettings(name: name)),
            );

    final theme = Theme.of(context);
    final style = theme.textTheme.button.copyWith(color: Colors.white);
    return IconTheme.merge(
      data: theme.primaryIconTheme,
      child: Column(children: [
        FlatButton(
          onPressed: navigateTo('posts', (c) => PostsPage()),
          child: Text('posts', style: style),
        ),
        FlatButton(
          onPressed: navigateTo('users', (c) => UsersPage()),
          child: Text('users', style: style),
        ),
      ]),
    );
  }
}
