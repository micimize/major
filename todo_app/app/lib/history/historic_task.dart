import 'package:flutter/material.dart';
import 'package:todo_app/schema.graphql.dart' hide document;
import 'package:todo_app/stopwatch/stopwatch.dart';

// TODO name collision with task_display
class TaskDisplay extends StatelessWidget {
  const TaskDisplay({
    Key key,
    @required this.task,
  }) : super(key: key);

  final Task task;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(
          task.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
        ),
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description.isNotEmpty)
              Text(task.description),
            Text(
              'CREATED ON ${_formatDatetime(task.created)}',
              style: Theme.of(context).textTheme.caption,
            ),
            if (task.isCompleted)
              Text(
                'COMPLETED ON ${_formatDatetime(task.closed)}',
                style: Theme.of(context).textTheme.caption,
              ),
          ],
        ),
        trailing: DisplayDuration(
          value: task.stopwatchValue?.elapsed,
          placeholder: 'todo',
        ),
      );
}

extension _Helpers on Task {
  bool get isCompleted => lifecycle == TaskLifecycle.COMPLETED;
}

String _formatDatetime(DateTime value) => [
      value.year.toString(),
      '-',
      value.month.toString().padLeft(2, '0'),
      '-',
      value.day.toString().padLeft(2, '0'),
      ' ',
      value.hour.toString().padLeft(2, '0'),
      ':',
      value.minute.toString().padLeft(2, '0'),
    ].join('');
