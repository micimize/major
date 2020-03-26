import 'package:built_collection/built_collection.dart';
import 'package:todo_app/schema.graphql.dart';

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
