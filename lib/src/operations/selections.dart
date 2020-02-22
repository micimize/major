part of 'operations.dart';

@immutable
class SelectionSet extends GraphQLClientEntity {
  const SelectionSet(this.astNode);

  @override
  final SelectionSetNode astNode;

  List<Selection> get selections =>
      astNode.selections.map(Selection.fromNode).toList();

  static SelectionSet fromNode(SelectionSetNode astNode) =>
      SelectionSet(astNode);
}

@immutable
abstract class Selection extends GraphQLClientEntity {
  const Selection();

  @override
  SelectionNode get astNode;

  static Selection fromNode(SelectionNode astNode) {
    if (astNode is FieldNode) {
      return Field.fromNode(astNode);
    }
    if (astNode is FragmentSpreadNode) {
      return FragmentSpread.fromNode(astNode);
    }
    if (astNode is InlineFragmentNode) {
      return InlineFragment.fromNode(astNode);
    }
    throw ArgumentError('$astNode is unsupported');
  }
}

@immutable
class Field extends Selection {
  const Field(this.astNode);

  @override
  final FieldNode astNode;

  String get alias => astNode.alias.value;
  String get name => astNode.name.value;

  List<Argument> get arguments =>
      astNode.arguments.map(Argument.fromNode).toList();

  List<Directive> get directives =>
      astNode.directives.map(Directive.fromNode).toList();

  SelectionSet get selectionSet => SelectionSet.fromNode(astNode.selectionSet);

  static Field fromNode(FieldNode astNode) => Field(astNode);
}

@immutable
class FragmentSpread extends Selection {
  const FragmentSpread(this.astNode);

  @override
  final FragmentSpreadNode astNode;

  String get name => astNode.name.value;

  List<Directive> get directives =>
      astNode.directives.map(Directive.fromNode).toList();

  static FragmentSpread fromNode(FragmentSpreadNode astNode) =>
      FragmentSpread(astNode);
}

@immutable
class InlineFragment extends Selection {
  const InlineFragment(this.astNode);

  @override
  final InlineFragmentNode astNode;

  TypeCondition get typeCondition =>
      TypeCondition.fromNode(astNode.typeCondition);

  List<Directive> get directives =>
      astNode.directives.map(Directive.fromNode).toList();

  SelectionSet get selectionSet => SelectionSet.fromNode(astNode.selectionSet);

  static InlineFragment fromNode(InlineFragmentNode astNode) =>
      InlineFragment(astNode);
}
