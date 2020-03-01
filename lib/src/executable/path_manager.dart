import 'package:meta/meta.dart';
import 'package:built_collection/built_collection.dart';

typedef PrintPath = String Function(Iterable<String> path);

abstract class PathManager<T> {
  @protected
  final Map<BuiltList<String>, T> registry = {};

  T valueFor(Iterable<String> path) => registry[path.toBuiltList()];

  T resolve(PathFocus<T> selectionPath);
}

class PathFocus<T> {
  PathFocus(this.manager, Iterable<String> path)
      : path = BuiltList<String>(path);

  PathFocus<T> extend(Iterable<String> other) =>
      PathFocus<T>(manager, path.followedBy(other));

  final PathManager<T> manager;
  final BuiltList<String> path;

  PathFocus<T> operator +(Object other) {
    if (other is String) {
      return extend([other]);
    }
    if (other is Iterable<String>) {
      return extend(other);
    }
    if (other is PathFocus) {
      return extend(other.path);
    }
    throw StateError(
      'Cannot add ${other.runtimeType} $other to PathFocus $this',
    );
  }

  T get resolved => manager.resolve(this);
}
