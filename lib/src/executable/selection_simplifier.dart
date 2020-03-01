import 'package:built_collection/built_collection.dart';

/// Simplifies operation selection set structures into more easily/logically traversable forms.
///
/// GraphQL Selection Sets can get fairly complicated, and resolve into structures that don't coorespond to the declaration graph.
/// For example, subfields are merged across same-named fields:
/// ```graphql
/// fragment withOrbitals on PlanetsConnection {
///   planets {
///     orbitalPeriod
///   }
/// }
///
/// {
///  allPlanets {
///     planets {
///       id
///     }
///     planets {
///       name
///     }
///     ...withOrbitals
///   }
/// }
///
/// # results in the same structure as
/// {
///   allPlanets {
///     planets {
///       id
///       name
///       orbitalPeriod
///     }
///   }
/// }
/// ```
///
/// This module simplifies the former above into the latter to the best of it's ability,
/// Making certain use-cases (like code generation) easier to implement.
///
/// NOTE: mutually recursive fragment spreads aren't valid in graphql
import 'package:meta/meta.dart';
import './definitions.dart';
import './path_manager.dart' as p;

abstract class Simplified implements Selection {
  /// The fragments this field are defined in
  Map<String, FragmentDefinition> get definedInFragments;

  PathFocus get path;
}

Map<String, FragmentDefinition> _mergedFragments<S extends Selection>(
  S maybeSimple,
  FragmentDefinition maybeFragment,
) =>
    {
      if (maybeSimple is Simplified) ...maybeSimple.definedInFragments,
      if (maybeFragment != null) maybeFragment.name: maybeFragment
    };

class SimplifiedField extends Field with Simplified {
  SimplifiedField(Field field, this._path, [FragmentDefinition fromFragment])
      : definedInFragments = _mergedFragments(field, fromFragment),
        super(
          field.astNode,
          field.schemaType,
          field.getType,
        );

  final PathFocus _path;

  @override
  PathFocus get path => _path + alias;

  @override
  final Map<String, FragmentDefinition> definedInFragments;
}

class SimplifiedInlineFragment extends InlineFragment with Simplified {
  SimplifiedInlineFragment(InlineFragment inlineFragment, this._path,
      [FragmentDefinition fromFragment])
      : definedInFragments = _mergedFragments(inlineFragment, fromFragment),
        super(
          inlineFragment.astNode,
          inlineFragment.schemaType,
          inlineFragment.getType,
        );

  final PathFocus _path;

  @override
  PathFocus get path => _path + 'on$onTypeName';

  @override
  final Map<String, FragmentDefinition> definedInFragments;
}

/// A composit selectionset that represents the merger of all selection sets defined at the same path
class SimplifiedSelectionSet extends SelectionSet {
  SimplifiedSelectionSet._(
    this.selectionSets,
    this.selections,
    this.path,
  ) : super(
          selectionSets.first.astNode,
          selectionSets.first.schemaType,
          selectionSets.first.getType,
        );

  factory SimplifiedSelectionSet(
      Iterable<SelectionSet> selectionSets, PathFocus path) {
    // flatten other simplified selection sets
    final _selectionSets =
        selectionSets.where((ss) => ss != null).expand<SelectionSet>(
      (ss) {
        if (ss is SimplifiedSelectionSet) {
          return ss.selectionSets;
        }
        return [ss];
      },
    ).toList();
    final selections = selectionSets
        .expand((ss) => ss.selections
            .expand((selection) => simplifySelection(selection, path)))
        .toList();
    return SimplifiedSelectionSet._(_selectionSets, selections, path);
  }

  final List<SelectionSet> selectionSets;

  final PathFocus path;

  @override
  final List<Selection> selections;

  /// Preserve fragmentSpreads so as to not lose useful info
  @override
  List<FragmentSpread> get fragmentSpreads {
    final spreadNames = <String>{};
    return selectionSets
        .expand((s) => s.fragmentSpreads)
        .where((spread) => spreadNames.add(spread.name))
        .toList();
  }
}

/// Flatten any fragment spreads into simplified fields, and add paths to fields
Iterable<Selection> simplifySelection(
  Selection selection,
  PathFocus path, [
  FragmentDefinition fromFragment,
]) sync* {
  if (selection is InlineFragment) {
    yield SimplifiedInlineFragment(selection, path, fromFragment);
  }
  if (selection is Field) {
    yield SimplifiedField(selection, path, fromFragment);
  }
  if (selection is FragmentSpread) {
    for (final s in selection.fragment.selectionSet.selections) {
      yield* simplifySelection(s, path, selection.fragment);
    }
  }

  throw StateError(
    'cannot simplify selection ${selection.runtimeType} $selection',
  );
}

class SelectionManager extends p.PathManager<SimplifiedSelectionSet> {
  SelectionManager();

  void register(Iterable<String> selectionPath, SelectionSet selectionSet) {
    final path = PathFocus(this, selectionPath);
    registry[path.path] = SimplifiedSelectionSet(
      [registry[path], selectionSet],
      path,
    );
  }

  @override
  SimplifiedSelectionSet resolve(path) => registry[path.path];
}

class PathFocus extends p.PathFocus<SelectionSet> {
  PathFocus(SelectionManager manager, Iterable<String> path)
      : super(manager, path);
  PathFocus.root([Iterable<String> path = const []])
      : super(SelectionManager(), path);

  SelectionManager get _manager => manager as SelectionManager;

  @override
  PathFocus extend(Iterable<String> other) =>
      PathFocus(_manager, path.followedBy(other));

  @override
  PathFocus operator +(Object other) {
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
}
