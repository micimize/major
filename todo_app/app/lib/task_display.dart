import 'package:flutter/material.dart';
import 'package:todo_app/schema.graphql.dart' hide document;
import 'package:todo_app/pointless_helpers.dart';
import 'package:todo_app/typed_mutation.dart';
import 'package:todo_app/complete_task.graphql.dart' as complete;

final CompleteTaskMutation = TypedMutation.factoryFor<
    complete.CompleteTaskResult, complete.CompleteTaskVariables>(
  documentNode: complete.document,
  dataFromJson: complete.CompleteTaskResult.fromJson,
);

class TaskDisplay extends StatelessWidget {
  const TaskDisplay({
    Key key,
    @required this.task,
  }) : super(key: key);

  final Task task;

  @override
  Widget build(BuildContext context) => CompleteTaskMutation(
        builder: ({
          runMutation,
          data,
          loading,
          exception,
        }) {
          return ListTile(
            leading: IconButton(
              onPressed: () => runMutation(
                complete.CompleteTaskVariables((b) => b..taskId = task.id),
              ),
              icon: Icon(
                task.isCompleted
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
              ),
            ),
            title: Text(task.title),
            subtitle: Text(task.description),
          );
        },
      );
}

extension _Helpers on Task {
  bool get isCompleted => lifecycle == TaskLifecycle.COMPLETED;
}
