import 'dart:collection';

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
import './definitions.dart';

abstract class Simplified implements Selection {
  /// The fragments this field are defined in
  Map<String, FragmentDefinition> get definedInFragments;

  BuiltList<String> get path;
}

Map<String, FragmentDefinition> _mergedFragments<S extends Selection>(
  S maybeSimple,
  Iterable<FragmentDefinition> fromFragments,
) =>
    {
      if (maybeSimple is Simplified) ...maybeSimple.definedInFragments,
      ...Map.fromEntries(fromFragments.map((f) => MapEntry(f.name, f)))
    };

class SimplifiedField extends Field with Simplified {
  SimplifiedField(
    Field field,
    this.selectionSet,
    this._path, [
    Iterable<FragmentDefinition> fromFragments,
  ])  : definedInFragments = _mergedFragments(field, fromFragments ?? []),
        super(
          field.astNode,
          field.schemaType,
          field.getType,
        );

  SimplifiedField mergedWith(SimplifiedField other) => SimplifiedField(
        this,
        SimplifiedSelectionSet([selectionSet, other.selectionSet], _path),
        _path,
        other.definedInFragments.values,
      );

  final BuiltList<String> _path;

  @override
  BuiltList<String> get path => _path.append(alias);

  @override
  final SelectionSet selectionSet;

  @override
  final Map<String, FragmentDefinition> definedInFragments;
}

class SimplifiedInlineFragment extends InlineFragment with Simplified {
  SimplifiedInlineFragment(
    InlineFragment inlineFragment,
    this.selectionSet,
    this._path, [
    Iterable<FragmentDefinition> fromFragments,
  ])  : definedInFragments =
            _mergedFragments(inlineFragment, fromFragments ?? []),
        super(
          inlineFragment.astNode,
          inlineFragment.schemaType,
          inlineFragment.getType,
        );

  SimplifiedInlineFragment mergedWith(SimplifiedInlineFragment other) =>
      SimplifiedInlineFragment(
        this,
        SimplifiedSelectionSet([selectionSet, other.selectionSet], _path),
        _path,
        other.definedInFragments.values,
      );

  @override
  final SelectionSet selectionSet;

  final BuiltList<String> _path;

  @override
  BuiltList<String> get path => _path.append('on$onTypeName');

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
    Iterable<SelectionSet> selectionSets,
    BuiltList<String> path,
  ) {
    // flatten other simplified selection sets
    final _selectionSets = selectionSets.expand<SelectionSet>(
      (ss) {
        if (ss == null) {
          return [];
        }
        if (ss is SimplifiedSelectionSet) {
          return ss.selectionSets;
        }
        return [ss];
      },
    ).toList();

    final selections = <String, Selection>{};
    for (final selection in _flattened(selectionSets, path)) {
      if (selections.containsKey(selection.alias)) {
        if (selection is SimplifiedField) {
          final existing = selections[selection.alias] as SimplifiedField;
          selections[selection.alias] = existing.mergedWith(selection);
        }
        if (selection is SimplifiedInlineFragment) {
          final existing =
              selections[selection.alias] as SimplifiedInlineFragment;
          selections[selection.alias] = existing.mergedWith(selection);
        }
      }
    }

    return SimplifiedSelectionSet._(
      _selectionSets,
      selections.values.toList(),
      path,
    );
  }

  final List<SelectionSet> selectionSets;

  final BuiltList<String> path;

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

Iterable<Selection> _flattened(
        Iterable<SelectionSet> selectionSets, BuiltList<String> path) =>
    selectionSets.expand(
      (ss) => ss.selections.expand(
        (selection) => _simplifySelectionFirstPass(selection, path),
      ),
    );

// TODO wrote this when I thought tracking paths would be important,
// but really flattening/merging is not as complicated as I was thinking
/// Flatten any fragment spreads into simplified fields, and add paths to fields
Iterable<Selection> _simplifySelectionFirstPass(
  Selection selection,
  BuiltList<String> path, [
  FragmentDefinition fromFragment,
]) sync* {
  if (selection is InlineFragment) {
    yield SimplifiedInlineFragment(
        selection, selection.selectionSet, path, [fromFragment]);
  }
  if (selection is Field) {
    yield SimplifiedField(
        selection, selection.selectionSet, path, [fromFragment]);
  }
  if (selection is FragmentSpread) {
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

extension GetSimplified on SelectionSet {
  //SimplifiedSelectionSet

}
