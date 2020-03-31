import 'package:flutter/material.dart';
import 'package:todo_app/navigation.dart';
import 'package:major_graphql_flutter/typed_query.dart';
import 'package:todo_app/history/all_tasks.graphql.dart' as all_tasks;
import 'package:todo_app/task_display.dart';

final AllTasksQuery = TypedQuery.factoryFor<all_tasks.GetAllTasksResult,
    all_tasks.GetAllTasksVariables>(
  documentNode: all_tasks.document,
  dataFromJson: all_tasks.GetAllTasksResult.fromJson,
);

final getAllTasksCacheKey = keyProviderFactory(
  documentNode: all_tasks.document,
  variables: all_tasks.GetAllTasksVariables(),
);

class TaskHistory extends StatelessWidget {
  TaskHistory({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AllTasksQuery(
        variables: all_tasks.GetAllTasksVariables(),
        builder: ({data, exception, loading}) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Task List'),
            ),
            bottomNavigationBar: NavBar(),
            body: Center(
              child: ListView(
                children: <Widget>[
                  if (loading) CircularProgressIndicator(),
                  ...[
                    if (!loading && data != null)
                      ...data.tasks.nodes.map(
                        (n) => n.toObjectBuilder().build(),
                      ),
                    // ...tasks,
                  ].map((t) => TaskDisplay(task: t)),
                ],
              ),
            ),
          );
        });
  }
}
