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
/// TODO: this is kinda a sloppy mess. The entire path mechanic seems unnecessary
import 'package:built_collection/built_collection.dart';
import './definitions.dart' as d;

export './definitions.dart' hide SelectionSet, InlineFragment, Field;

abstract class Simplified implements d.Selection {
  /// The fragments this field are defined in
  Map<String, d.FragmentDefinition> get definedInFragments;

  BuiltList<String> get path;
}

Map<String, d.FragmentDefinition> _mergedFragments<S extends d.Selection>(
  S maybeSimple,
  Iterable<d.FragmentDefinition> fromFragments,
) =>
    {
      if (maybeSimple is Simplified) ...maybeSimple.definedInFragments,
      ...Map.fromEntries(fromFragments.map((f) => MapEntry(f.name, f)))
    };

class Field extends d.Field with Simplified {
  Field(
    d.Field field,
    this.selectionSet,
    this._path, [
    Iterable<d.FragmentDefinition> fromFragments,
  ])  : definedInFragments = _mergedFragments(field, fromFragments ?? []),
        super(
          field.astNode,
          field.schemaType,
          field.getType,
        );

  Field mergedWith(Field other) => Field(
        this,
        SelectionSet([selectionSet, other.selectionSet], _path),
        _path,
        other.definedInFragments.values,
      );

  final BuiltList<String> _path;

  @override
  BuiltList<String> get path => _path.append(alias);

  @override
  final SelectionSet selectionSet;

  @override
  final Map<String, d.FragmentDefinition> definedInFragments;
}

class InlineFragment extends d.InlineFragment with Simplified {
  InlineFragment(
    d.InlineFragment inlineFragment,
    this.selectionSet,
    this._path, [
    Iterable<d.FragmentDefinition> fromFragments,
  ])  : definedInFragments =
            _mergedFragments(inlineFragment, fromFragments ?? []),
        super(
          inlineFragment.astNode,
          inlineFragment.schemaType,
          inlineFragment.getType,
        );

  InlineFragment mergedWith(InlineFragment other) => InlineFragment(
        this,
        SelectionSet([selectionSet, other.selectionSet], _path),
        _path,
        other.definedInFragments.values,
      );

  @override
  final SelectionSet selectionSet;

  final BuiltList<String> _path;

  @override
  BuiltList<String> get path => _path.append('on$onTypeName');

  @override
  final Map<String, d.FragmentDefinition> definedInFragments;
}

/// A composit selectionset that represents the merger of all selection sets defined at the same path
class SelectionSet extends d.SelectionSet {
  SelectionSet._(
    this.selectionSets,
    this.selections,
    this.path,
  ) : super(
          selectionSets.first.astNode,
          selectionSets.first.schemaType,
          selectionSets.first.getType,
        );

  factory SelectionSet(
    Iterable<d.SelectionSet> selectionSets,
    BuiltList<String> path,
  ) {
    // flatten other simplified selection sets
    final _selectionSets = selectionSets.expand<d.SelectionSet>(
      (ss) {
        if (ss == null) {
          return [];
        }
        if (ss is SelectionSet) {
          return ss.selectionSets;
        }
        return [ss];
      },
    ).toList();

    final selections = <String, d.Selection>{};
    for (final selection in _flattened(selectionSets, path)) {
      if (selections.containsKey(selection.alias)) {
        if (selection is Field) {
          final existing = selections[selection.alias] as Field;
          selections[selection.alias] = existing.mergedWith(selection);
        }
        if (selection is InlineFragment) {
          final existing = selections[selection.alias] as InlineFragment;
          selections[selection.alias] = existing.mergedWith(selection);
        }
      }
    }

    return SelectionSet._(
      _selectionSets,
      selections.values.toList(),
      path,
    );
  }

  final List<d.SelectionSet> selectionSets;

  final BuiltList<String> path;

  @override
  final List<d.Selection> selections;

  @override
  List<Field> get fields => selections.whereType<Field>().toList();

  @override
  List<InlineFragment> get inlineFragments =>
      selections.whereType<InlineFragment>().toList();

  /// Preserve fragmentSpreads so as to not lose useful info
  @override
  List<d.FragmentSpread> get fragmentSpreads {
    final spreadNames = <String>{};
    return selectionSets
        .expand((s) => s.fragmentSpreads)
        .where((spread) => spreadNames.add(spread.name))
        .toList();
  }
}

Iterable<d.Selection> _flattened(
        Iterable<d.SelectionSet> selectionSets, BuiltList<String> path) =>
    selectionSets.expand(
      (ss) => ss.selections.expand(
        (selection) => _simplifySelectionFirstPass(selection, path),
      ),
    );

// TODO wrote this when I thought tracking paths would be important,
// but really flattening/merging is not as complicated as I was thinking
/// Flatten any fragment spreads into simplified fields, and add paths to fields
Iterable<d.Selection> _simplifySelectionFirstPass(
  d.Selection selection,
  BuiltList<String> path, [
  d.FragmentDefinition fromFragment,
]) sync* {
  if (selection is d.InlineFragment) {
    yield InlineFragment(
      selection,
      SelectionSet([selection.selectionSet], path),
      path,
      [fromFragment],
    );
  }
  if (selection is d.Field) {
    yield Field(
      selection,
      SelectionSet([selection.selectionSet], path),
      path,
      [fromFragment],
    );
  }
  if (selection is d.FragmentSpread) {
    for (final s in selection.fragment.selectionSet.selections) {
      yield* _simplifySelectionFirstPass(s, path, selection.fragment);
    }
  }

  throw StateError(
    'cannot simplify selection ${selection.runtimeType} $selection',
  );
}

extension Append<T> on BuiltList<T> {
  BuiltList<T> append(T other) => followedBy([other]).toBuiltList();
}

extension GetSimplified on d.SelectionSet {
  SelectionSet get simplified => SelectionSet(
        [this],
        <String>[].toBuiltList(),
      );
}
