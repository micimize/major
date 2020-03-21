import 'package:flutter/material.dart';
import 'package:todo_app/create_task_form.dart';
import 'package:todo_app/schema.graphql.dart';
import 'package:todo_app/pointless_helpers.dart';

class TaskList extends StatefulWidget {
  TaskList({Key key}) : super(key: key);

  @override
  TaskListState createState() => TaskListState();
}

class TaskListState extends State<TaskList> {
  List<Task> tasks = [
    _testTasks[0],
    _testTasks[1],
    _testTasks[3],
  ];

  VoidCallback taskCompleter(Task completed) => () => setState(
        () => tasks = tasks.map((task) {
          if (task.id == completed.id) {
            return task.rebuild((b) => b..lifecycle = TaskLifecycle.COMPLETED);
          }
          return task;
        }).toList(),
      );

  void generateRandomTask() => setState(() {
        tasks.add(_testTasks[tasks.length]);
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            ...tasks.map((t) => TaskDisplay(
                  task: t,
                  complete: taskCompleter(t),
                )),
            Expanded(child: Container()),
            ListTile(title: CreateTaskForm()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: generateRandomTask,
        tooltip: 'Generate Random Task',
        child: Icon(Icons.add),
      ),
    );
  }
}

class TaskDisplay extends StatelessWidget {
  const TaskDisplay({
    Key key,
    @required this.task,
    @required this.complete,
  }) : super(key: key);

  final Task task;
  final VoidCallback complete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        onPressed: complete,
        icon: Icon(
          task.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
        ),
      ),
      title: Text(task.title),
      subtitle: Text(task.description),
    );
  }
}

extension _Helpers on Task {
  bool get isCompleted => lifecycle == TaskLifecycle.COMPLETED;
}

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
