import 'package:flutter/material.dart';
import 'package:major_components/major_components.dart';
import 'package:major_components_example/back_nav.dart';
import 'package:major_components_example/data.dart';

class UsersPage extends StatelessWidget {
  UsersPage();
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
          back: header('user back layer'),
          front: header('users front'),
        ),
        backLayer: BackNav(),
        frontLayer: UserList(),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: posts.length,
        itemBuilder: (c, i) {
          final u = users[i];
          return ListTile(
            isThreeLine: true,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              children: [
                Text(u.fullName),
                Expanded(child: Container()),
                Text('@' + u.username,
                    style: Theme.of(context).textTheme.caption),
              ],
            ),
            subtitle: Text(
              u.bio,
              maxLines: 2,
            ),
          );
        });
  }
}
