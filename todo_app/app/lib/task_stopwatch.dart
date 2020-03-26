import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/dev_utils.dart';
import 'package:todo_app/schema.graphql.dart';

extension WithStopwatchHelpers on DatetimeInterval {
  Duration get duration => end.difference(start);

  DatetimeInterval get asIfCompleted =>
      rebuild((b) => b.end ??= DateTime.now().toUtc());
}

extension StructuredStopwatch on BuiltList<DatetimeInterval> {
  bool get isOngoing => isNotEmpty && last.end == null;

  BuiltList<DatetimeInterval> get asIfCompleted {
    if (!isOngoing) {
      return this;
    }
    return rebuild((b) => b..last = b.last.asIfCompleted);
  }

  Duration get totalElapsed => asIfCompleted
      .map((i) => i.duration)
      .reduce((total, partial) => total + partial);

  // TODO grab iso duration
  String display() {
    var d = totalElapsed.toString().split('.');
    d.removeLast();
    return d.join('.');
  }

  static final empty = BuiltList<DatetimeInterval>();
}

class TaskStopwatch extends StatefulWidget {
  TaskStopwatch({
    Key key,
    BuiltList<DatetimeInterval> value,
    this.onChanged,
  })  : value = value ?? StructuredStopwatch.empty,
        super(key: key);

  final BuiltList<DatetimeInterval> value;

  final void Function(BuiltList<DatetimeInterval>) onChanged;

  @override
  _TaskStopwatchState createState() => _TaskStopwatchState();
}

class _TaskStopwatchState extends State<TaskStopwatch>
    with TickerProviderStateMixin {
  VoidCallback toggleWith(
    dynamic Function(ListBuilder<DatetimeInterval> list) updates,
  ) =>
      () => widget.onChanged(widget.value.rebuild(updates));

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.value.display() ?? ' todo',
      style: Theme.of(context).textTheme.caption,
    );
    if (widget.value.isOngoing) {
      return IconButton(
        icon: Icon(Icons.pause),
        onPressed: toggleWith(
          (b) => b
            ..last = b.last.rebuild(
              (b) => b.end = DateTime.now().toUtc(),
            ),
        ),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.play_arrow),
        onPressed: toggleWith(
          (b) => b.add(
            DatetimeInterval(
              (b) => b..start = DateTime.now().toUtc(),
            ),
          ),
        ),
      );
    }
  }
}
