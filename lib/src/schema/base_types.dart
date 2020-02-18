// Contents:
// * GraphQLEntity
// * AbstractType
// * NamedType
// * ListType
// * Argument
// * Directive
// * TypeSystemDefinition
// * TypeDefinition
part of 'schema.dart';

@immutable
abstract class GraphQLEntity {
  const GraphQLEntity();

  @override
  String toString() => printNode(astNode);

  Node get astNode;
}

mixin AbstractType on GraphQLEntity {}

@immutable
class NamedType extends GraphQLEntity {
  const NamedType(this.astNode);

  @override
  final NamedTypeNode astNode;

  static NamedType fromNode(NamedTypeNode astNode) => NamedType(astNode);
}

@immutable
class ListType extends GraphQLEntity {
  const ListType(this.astNode);

  @override
  final ListTypeNode astNode;

  TypeNode get type => astNode.type;

  static ListType fromNode(ListTypeNode astNode) => ListType(astNode);
}

@immutable
class Argument extends GraphQLEntity {
  const Argument(this.astNode);

  @override
  final ArgumentNode astNode;

  String get name => astNode.name.value;
  Value get value => Value.fromNode(astNode.value);

  static Argument fromNode(ArgumentNode astNode) => Argument(astNode);
}

@immutable
class Directive extends GraphQLEntity {
  const Directive(this.astNode);

  @override
  final DirectiveNode astNode;

  String get name => astNode.name.value;

  List<Argument> get arguments =>
      astNode.arguments.map(Argument.fromNode).toList();

  static Directive fromNode(DirectiveNode astNode) => Directive(astNode);
}

@immutable
abstract class TypeSystemDefinition extends GraphQLEntity {
  const TypeSystemDefinition();

  @override
  TypeSystemDefinitionNode get astNode;

  String get name => astNode.name.value;
}

@immutable
abstract class TypeDefinition extends TypeSystemDefinition {
  const TypeDefinition();

  @override
  TypeDefinitionNode get astNode;

  String get description => astNode.description.value;

  List<Directive> get directives =>
      astNode.directives.map(Directive.fromNode).toList();

  static TypeDefinition fromNode(TypeDefinitionNode node) {
    if (node is ScalarTypeDefinitionNode) {
      return ScalarTypeDefinition.fromNode(node);
    }

    if (node is InterfaceTypeDefinitionNode) {
      return InterfaceTypeDefinition.fromNode(node);
    }

    if (node is ObjectTypeDefinitionNode) {
      return ObjectTypeDefinition.fromNode(node);
    }

    if (node is UnionTypeDefinitionNode) {
      return UnionTypeDefinition.fromNode(node);
    }

    if (node is EnumTypeDefinitionNode) {
      return EnumTypeDefinition.fromNode(node);
    }

    if (node is InputObjectTypeDefinitionNode) {
      return InputObjectTypeDefinition.fromNode(node);
    }

    /* 
    https://github.com/graphql/graphql-js/blob/49d86bbc810d1203aa3f7d93252e51f257d9460f/src/language/predicates.js#L59
    doesn't include enum values
    if (node is EnumValueDefinitionNode) {
      return EnumValueDefinition.fromNode(node);
    }
    */

    throw ArgumentError('$node is unsupported');
  }
}
