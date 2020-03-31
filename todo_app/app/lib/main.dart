import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:todo_app/navigation.dart';
import 'package:todo_app/history/history_page.dart';
import 'package:todo_app/task_list/task_list.dart';
import 'package:todo_app/user_auth.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ValueNotifier<GraphQLClient> client = ValueNotifier<GraphQLClient>(
      GraphQLClient(
        cache: OptimisticCache(
          dataIdFromObject: typenameDataIdFromObject,
        ),
        link: googleSignInLink.concat(
          HttpLink(
            uri: 'http://localhost:5000/graphql',
            headers: {"Accept": "application/json"},
          ),
        ),
      ),
    );
    return GraphQLProvider(
      client: client,
      child: CacheProvider(
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: AuthenticationProvider(
            child: SafeArea(
              maintainBottomViewPadding: true,
              child: ControlledTabView(children: [
                TaskList(),
                TaskHistory(),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
