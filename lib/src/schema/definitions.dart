part of 'schema.dart';

@immutable
class ScalarTypeDefinition extends TypeDefinition {
  const ScalarTypeDefinition(this.astNode);

  @override
  final ScalarTypeDefinitionNode astNode;

  static ScalarTypeDefinition fromNode(ScalarTypeDefinitionNode astNode) =>
      ScalarTypeDefinition(astNode);
}

@immutable
class InputValueDefinition {
  const InputValueDefinition(this.astNode);

  final InputValueDefinitionNode astNode;

  static InputValueDefinition fromNode(InputValueDefinitionNode astNode) =>
      InputValueDefinition(astNode);
}

@immutable
class InterfaceTypeDefinition extends TypeDefinition with AbstractType {
  const InterfaceTypeDefinition(this.astNode);

  @override
  final InterfaceTypeDefinitionNode astNode;

  static InterfaceTypeDefinition fromNode(
          InterfaceTypeDefinitionNode astNode) =>
      InterfaceTypeDefinition(astNode);
}

@immutable
class UnionTypeDefinition extends TypeDefinition with AbstractType {
  const UnionTypeDefinition(this.astNode);

  @override
  final UnionTypeDefinitionNode astNode;

  static UnionTypeDefinition fromNode(UnionTypeDefinitionNode astNode) =>
      UnionTypeDefinition(astNode);
}

@immutable
class EnumTypeDefinition extends TypeDefinition {
  const EnumTypeDefinition(this.astNode);

  @override
  final EnumTypeDefinitionNode astNode;

  static EnumTypeDefinition fromNode(EnumTypeDefinitionNode astNode) =>
      EnumTypeDefinition(astNode);
}

@immutable
class EnumValueDefinition extends TypeDefinition {
  const EnumValueDefinition(this.astNode);

  @override
  final EnumValueDefinitionNode astNode;

  static EnumValueDefinition fromNode(EnumValueDefinitionNode astNode) =>
      EnumValueDefinition(astNode);
}

@immutable
class InputObjectTypeDefinition extends TypeDefinition {
  const InputObjectTypeDefinition(this.astNode);

  @override
  final InputObjectTypeDefinitionNode astNode;

  static InputObjectTypeDefinition fromNode(
          InputObjectTypeDefinitionNode astNode) =>
      InputObjectTypeDefinition(astNode);
}

@immutable
class DirectiveDefinition extends TypeSystemDefinition {
  const DirectiveDefinition(this.astNode);

  @override
  final DirectiveDefinitionNode astNode;

  static DirectiveDefinition fromNode(DirectiveDefinitionNode astNode) =>
      DirectiveDefinition(astNode);
}
