import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/dev_utils.dart';
import 'package:todo_app/schema.graphql.dart';
import 'package:todo_app/stopwatch/stopwatch.dart';

typedef OnStopwatchChanged = void Function(BuiltList<DatetimeInterval>);

// todo we want start to be non-null
extension WithStopwatchHelpers on DatetimeInterval {
  Duration get duration => end == null ? null : end.difference(start);

  DatetimeInterval get stopped =>
      rebuild((b) => b.end ??= DateTime.now().toUtc());
}

extension StructuredStopwatch on BuiltList<DatetimeInterval> {
  bool get isOngoing => isNotEmpty && last.end == null;

  BuiltList<DatetimeInterval> get stopped {
    if (!isOngoing) {
      return this;
    }
    return rebuild((b) => b..last = b.last.stopped);
  }

  BuiltList<DatetimeInterval> get started {
    if (isOngoing) {
      return this;
    }
    return rebuild(
      (b) => b.add(
        DatetimeInterval(
          (b) => b..start = DateTime.now().toUtc(),
        ),
      ),
    );
  }

  Duration get elapsed => isEmpty
      ? Duration.zero
      : stopped.map((i) => i.duration).reduce(
            (total, partial) => total + partial,
          );

  // TODO grab iso duration
  String display() {
    var d = elapsed.toString().split('.');
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

  final OnStopwatchChanged onChanged;

  @override
  _TaskStopwatchState createState() => _TaskStopwatchState();
}

class _TaskStopwatchState extends State<TaskStopwatch>
    with SingleTickerProviderStateMixin {
  VoidCallback toggleWith(
    dynamic Function(ListBuilder<DatetimeInterval> list) updates,
  ) =>
      () => widget.onChanged(widget.value.rebuild(updates));

  IconButton get button {
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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('boom');
    return DisplayStopwatch(
      value: widget.value,
      onChanged: widget.onChanged,
    );
    return Container(
      width: 108,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            widget.value.display() ?? ' todo',
            style: Theme.of(context).textTheme.caption,
          ),
          button,
        ],
      ),
    );
  }
}
