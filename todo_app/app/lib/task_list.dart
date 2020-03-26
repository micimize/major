import 'package:flutter/material.dart';
import 'package:todo_app/create_task_form.dart';
import 'package:todo_app/dev_utils.dart';
import 'package:todo_app/schema.graphql.dart' hide document;
import 'package:todo_app/pointless_helpers.dart';
import 'package:todo_app/typed_query.dart';
import 'package:todo_app/get_tasks.graphql.dart' as get_tasks;
import 'package:todo_app/task_display.dart';

final GetTasksQuery = TypedQuery.factoryFor<get_tasks.GetAllTasksResult,
    get_tasks.GetAllTasksVariables>(
  documentNode: get_tasks.document,
  dataFromJson: get_tasks.GetAllTasksResult.fromJson,
);

final getTasksCacheKey = keyProviderFactory(
  documentNode: get_tasks.document,
  variables: get_tasks.GetAllTasksVariables(),
);

class TaskList extends StatefulWidget {
  TaskList({Key key}) : super(key: key);

  @override
  TaskListState createState() => TaskListState();
}

class TaskListState extends State<TaskList> {
//List<Task> tasks = [
//  _testTasks[0],
//  _testTasks[1],
//  _testTasks[3],
//];

//VoidCallback taskCompleter(Task completed) => () => setState(
//      () => tasks = tasks.map((task) {
//        if (task.id == completed.id) {
//          return task.rebuild((b) => b..lifecycle = TaskLifecycle.COMPLETED);
//        }
//        return task;
//      }).toList(),
//    );

//void generateRandomTask() => setState(() {
//      tasks.add(_testTasks[tasks.length]);
//    });

  @override
  Widget build(BuildContext context) {
    return GetTasksQuery(
        variables: get_tasks.GetAllTasksVariables(),
        builder: ({data, exception, loading}) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Task List'),
            ),
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
                  ListTile(title: CreateTaskForm()),
                ],
              ),
            ),
            /*
            floatingActionButton: FloatingActionButton(
              onPressed: generateRandomTask,
              tooltip: 'Generate Random Task',
              child: Icon(Icons.add),
            ),
            */
          );
        });
  }
}

/*
final _testTasks = [
  TaskBuilder()
    ..title = 'watch indiana jones'
    ..description = 'bum panda sdj',
  TaskBuilder()
    ..title = 'eat cotton candy'
    ..description = 'yum',
  TaskBuilder()
    ..title = 'watch noopkat'
    ..description = 'weee',
  TaskBuilder()
    ..title = 'subscribe to Michael Joseph Rosenthal'
    ..description = 'on youtooobe',
  TaskBuilder()
    ..title = 'Actual attempt to get a stream audience'
    ..description = 'stop being such a coward and post in the discord',
  TaskBuilder()
    ..title = 'title'
    ..description = 'description',
  TaskBuilder()
    ..title = 'eat my shorts'
    ..description = 'yum',
  TaskBuilder()
    ..title = 'brush my teeth'
    ..description = 'yuk',
]
    .map(
      withIndex(
        (builder, id) => (builder
              ..lifecycle = TaskLifecycle.TODO
              ..id = '$id')
            .build(),
      ),
    )
    .toList();

*/
