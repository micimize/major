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

  Map<String, FragmentDefinition> _mergedFragments<S extends Selection>(S maybeSimple, FragmentDefinition maybeFragment,) =>
   {
    if(maybeSimple is Simplified) ...maybeSimple.definedInFragments,
    if (maybeFragment != null)
    maybeFragment.name: maybeFragment
    };

class SimplifiedField extends Field with Simplified {
  SimplifiedField(Field field, this.path, [FragmentDefinition fromFragment]): 
  definedInFragments = _mergedFragments(field, fromFragment),
  super(
        field.astNode,
         field.schemaType,
        field.getType,
  );

  @override
  final PathFocus path;

  @override
  final Map<String, FragmentDefinition> definedInFragments;

}

class SimplifiedInlineFragment extends InlineFragment with Simplified {
  SimplifiedInlineFragment(InlineFragment inlineFragment, this.path, [FragmentDefinition fromFragment]): 
  definedInFragments = _mergedFragments(inlineFragment, fromFragment),
  super(
        inlineFragment.astNode,
         inlineFragment.schemaType,
        inlineFragment.getType,
  );

  @override
  final PathFocus path;

  @override
  final Map<String, FragmentDefinition> definedInFragments;

}

class SimplifiedSelectionSet extends SelectionSet {
  SimplifiedSelectionSet (SelectionSet selectionSet)
  : super(
        selectionSet.astNode,
         selectionSet.schemaType,
        selectionSet.getType,
  );

  List<Selection> get selections => astNode.selections
      .map((selection) => Selection.fromNode(selection, schemaType, getType))
      .toList();

  /// selections with all fragment spreads inlined
  _FlattenedSelectionSet get simplified => _FlattenedSelectionSet(selections);

  List<Field> get fields => selections.whereType<Field>().toList();

  /// we maintain fragmentSpreads so as to not lose info
  @override
  List<FragmentSpread> get fragmentSpreads =>
      super.selections.whereType<FragmentSpread>().toList();

  List<InlineFragment> get inlineFragments =>
      selections.whereType<InlineFragment>().toList();

}

extension SimplifyHelpers on Selection {
  static Iterable<Selection> simplify(Selection selection,
PathFocus path, [FragmentDefinition fromFragment] 
  ) sync*{
    if (selection is InlineFragment) {
      yield SimplifiedInlineFragment(selection, path, fromFragment);
    }
    if (selection is Field) {
      yield SimplifiedField(selection, path, fromFragment);
    }
    if (selection is FragmentSpread) {
      for (final s in selection.fragment.selectionSet.selections){
        yield * simplify(s, path, selection.fragment);
      }
    }

    throw StateError(
      'cannot simplify selection ${selection.runtimeType} $selection',
    );
  }
}

class _FlattenedSelectionSet {
  _FlattenedSelectionSet(Iterable<Selection> selections) {
    _selections = List.unmodifiable(selections.expand<Selection>(_flatten));
  }

  final _fragmentSpreadNames = <String>{};
  List<Selection> _selections;

  List<Selection> get selections => _selections;

  List<String> get fragmentSpreadNames =>
      List.unmodifiable(_fragmentSpreadNames);

  List<Field> get fields => selections.whereType<Field>().toList();

  List<InlineFragment> get inlineFragments =>
      selections.whereType<InlineFragment>().toList();

  Iterable<Selection> _flatten(Selection selection) {
    if (selection is FragmentSpread) {
      _fragmentSpreadNames.add(selection.name);
      final selections = selection.fragment.selectionSet.selections;
      return selections.expand((innerSelection) {
        // swallow already seen fragment spreads
        if (innerSelection is FragmentSpread) {
          return _fragmentSpreadNames.contains(selection.name)
              ? []
              : _flatten(innerSelection);
        }

        // TODO flatten is a confusing name for a boolean flag
        return [Selection._flatten(selection)];
      });
    }

    return [selection];
  }
}



class SelectionManager extends PathManager<> {
  SelectionManager();

  @override
  String resolve(Iterable<String> selectionPath) => className(selectionPath);
}

class PathFocus extends p.PathFocus<SelectionSet> {
  PathFocus(ClassNameManager manager, Iterable<String> path)
      : super(manager, path);
  PathFocus.root([Iterable<String> path = const []])
      : super(ClassNameManager(), path);

  @override
  ClassNameManager get _manager => manager as ClassNameManager;

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

  String get className => resolved;
}