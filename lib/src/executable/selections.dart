part of 'definitions.dart';

@immutable
class SelectionSet extends ExecutableWithResolver {
  const SelectionSet(
    this.astNode, [
    this.schemaType,
    GetExecutableType getType,
  ]) : super(getType);

  final TypeDefinition schemaType;

  @override
  final SelectionSetNode astNode;

  List<Selection> get selections => astNode.selections
      .map((selection) => Selection.fromNode(selection, schemaType, getType))
      .toList();

  /// selections with all fragment spreads inlined
  _FlattenedSelectionSet get flattened => _FlattenedSelectionSet(selections);

  List<Field> get fields => selections.whereType<Field>().toList();

  List<FragmentSpread> get fragmentSpreads =>
      selections.whereType<FragmentSpread>().toList();

  List<InlineFragment> get inlineFragments =>
      selections.whereType<InlineFragment>().toList();

  static SelectionSet fromNode(
    SelectionSetNode astNode, [
    TypeDefinitionWithFieldSet schemaType,
    GetExecutableType getType,
  ]) =>
      SelectionSet(astNode, schemaType, getType);
}

@immutable
abstract class Selection extends ExecutableWithResolver {
  const Selection([GetExecutableType getType])
      : flattened = false,
        super(getType);

  const Selection._flattened([GetExecutableType getType])
      : flattened = true,
        super(getType);

  GraphQLEntity get schemaType;

  /// Whether this selection is was pulled from a fragment spread.
  /// Used in code generation to `@override`
  final bool flattened;

  @override
  SelectionNode get astNode;

  static Selection _flatten(Selection selection) {
    if (selection is InlineFragment) {
      return InlineFragment._flattened(selection);
    }
    if (selection is Field) {
      return Field._flattened(selection);
    }
    throw StateError(
      'cannot flatten selection ${selection.runtimeType} $selection',
    );
  }

  static Selection fromNode(
    SelectionNode astNode, [

    /// The [schemaType] of the containing element
    TypeDefinition schemaType,
    GetExecutableType getType,
  ]) {
    if (astNode is FieldNode) {
      // fields can only be seleted on Interface and Object types
      final fieldType = (schemaType != null)
          ? (schemaType as TypeDefinitionWithFieldSet)
              .getField(astNode.name.value)
          : null;
      return Field(astNode, fieldType, getType);
    }

    if (astNode is FragmentSpreadNode) {
      // Fragments can be specified on object types, interfaces, and unions.
      // TODO need another mechanism for saturating fragment spreads.
      // Probably adding a fragmentSpread argument to the getType when within the executable context.
      return FragmentSpread(astNode, schemaType, getType);
    }
    if (astNode is InlineFragmentNode) {
      // inline fragments must always specify a type condition,
      final onType = getType.fromSchema(astNode.typeCondition.on.name.value);
      return InlineFragment(astNode, onType, getType);
    }

    throw ArgumentError('$astNode is unsupported');
  }
}

@immutable
class Field extends Selection {
  const Field(
    this.astNode, [
    this.schemaType,
    GetExecutableType getType,
  ]) : super(getType);

  Field._flattened(Field field)
      : astNode = field.astNode,
        schemaType = field.schemaType,
        super._flattened(field.getType);

  @override
  final FieldNode astNode;

  @override
  final FieldDefinition schemaType;

  String get alias => astNode.alias?.value ?? name;
  String get name => astNode.name.value;

  GraphQLType get type => schemaType.type;

  List<Argument> get arguments =>
      astNode.arguments.map(Argument.fromNode).toList();

  List<Directive> get directives =>
      astNode.directives.map(Directive.fromNode).toList();

  SelectionSet get selectionSet => astNode.selectionSet != null
      ? SelectionSet(
          astNode.selectionSet,
          getType.fromSchema(type.baseTypeName),
          getType,
        )
      : null;

  static Field fromNode(FieldNode astNode) => Field(astNode);
}

@immutable
class FragmentSpread extends Selection {
  const FragmentSpread(this.astNode,
      [this.schemaType, GetExecutableType getType])
      : super(getType);

  @override
  final FragmentSpreadNode astNode;

  @override
  final TypeDefinition schemaType;

  String get name => astNode.name.value;

  FragmentDefinition get fragment => getType.fromFragments(name);

  List<Directive> get directives =>
      astNode.directives.map(Directive.fromNode).toList();

  static FragmentSpread fromNode(FragmentSpreadNode astNode) =>
      FragmentSpread(astNode);
}

@immutable
class InlineFragment extends Selection {
  const InlineFragment(
    this.astNode, [
    this.schemaType,
    GetExecutableType getType,
  ]) : super(getType);

  InlineFragment._flattened(InlineFragment inline)
      : astNode = inline.astNode,
        schemaType = inline.schemaType,
        super._flattened(inline.getType);

  @override
  final InlineFragmentNode astNode;

  TypeCondition get typeCondition =>
      TypeCondition.fromNode(astNode.typeCondition);

  TypeDefinitionWithFieldSet get onType =>
      getType.fromSchema(onTypeName) as TypeDefinitionWithFieldSet;

  String get onTypeName => typeCondition.on.name;

  @override
  final TypeDefinition schemaType;

  List<Directive> get directives =>
      astNode.directives.map(Directive.fromNode).toList();

  SelectionSet get selectionSet =>
      SelectionSet.fromNode(astNode.selectionSet, onType, getType);

  static InlineFragment fromNode(InlineFragmentNode astNode) =>
      InlineFragment(astNode);
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
      return selections.expand((selection) {
        // swallow already seen fragment spreads
        if (selection is FragmentSpread) {
          return _fragmentSpreadNames.contains(selection.name)
              ? []
              : _flatten(selection);
        }

        // TODO flatten is a confusing name for a boolean flag
        return [Selection._flatten(selection)];
      });
    }

    return [selection];
  }
}
