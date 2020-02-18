// Contents:
// * FieldDefinition
// * ScalarTypeDefinition
// * InputValueDefinition
// * InterfaceTypeDefinition
// * ObjectTypeDefinition
// * UnionTypeDefinition
// * EnumTypeDefinition
// * EnumValueDefinition
// * InputObjectTypeDefinition
// * DirectiveDefinition
part of 'schema.dart';

@immutable
class FieldDefinition extends GraphQLEntity {
  const FieldDefinition(this.astNode);

  @override
  final FieldDefinitionNode astNode;

  String get description => astNode.description.value;

  String get name => astNode.name.value;

  //TypeNode get type => astNode.type;

  List<Directive> get directive =>
      astNode.directives.map(Directive.fromNode).toList();

  List<InputValueDefinition> get args =>
      astNode.args.map(InputValueDefinition.fromNode).toList();

  static FieldDefinition fromNode(FieldDefinitionNode astNode) =>
      FieldDefinition(astNode);
}

@immutable
class ScalarTypeDefinition extends TypeDefinition {
  const ScalarTypeDefinition(this.astNode);

  @override
  final ScalarTypeDefinitionNode astNode;

  static ScalarTypeDefinition fromNode(ScalarTypeDefinitionNode astNode) =>
      ScalarTypeDefinition(astNode);
}

@immutable
class InputValueDefinition extends GraphQLEntity {
  const InputValueDefinition(this.astNode);

  @override
  final InputValueDefinitionNode astNode;

  String get description => astNode.description.value;
  String get name => astNode.name.value;
  TypeNode get type => astNode.type;
  Value get defaultValue => Value.fromNode(astNode.defaultValue);
  List<Directive> get directives =>
      astNode.directives.map(Directive.fromNode).toList();

  static InputValueDefinition fromNode(InputValueDefinitionNode astNode) =>
      InputValueDefinition(astNode);
}

@immutable
class InterfaceTypeDefinition extends TypeDefinition with AbstractType {
  const InterfaceTypeDefinition(this.astNode);

  @override
  final InterfaceTypeDefinitionNode astNode;

  List<FieldDefinition> get fields =>
      astNode.fields.map(FieldDefinition.fromNode).toList();

  static InterfaceTypeDefinition fromNode(
          InterfaceTypeDefinitionNode astNode) =>
      InterfaceTypeDefinition(astNode);
}

@immutable
class ObjectTypeDefinition extends TypeDefinition {
  const ObjectTypeDefinition(this.astNode);

  @override
  final ObjectTypeDefinitionNode astNode;

  List<NamedType> get interfaces =>
      astNode.interfaces.map(NamedType.fromNode).toList();

  List<FieldDefinition> get fields =>
      astNode.fields.map(FieldDefinition.fromNode).toList();

  static ObjectTypeDefinition fromNode(ObjectTypeDefinitionNode astNode) =>
      ObjectTypeDefinition(astNode);
}

@immutable
class UnionTypeDefinition extends TypeDefinition with AbstractType {
  const UnionTypeDefinition(this.astNode);

  @override
  final UnionTypeDefinitionNode astNode;

  List<NamedTypeNode> get types => astNode.types;

  static UnionTypeDefinition fromNode(UnionTypeDefinitionNode astNode) =>
      UnionTypeDefinition(astNode);
}

@immutable
class EnumTypeDefinition extends TypeDefinition {
  const EnumTypeDefinition(this.astNode);

  @override
  final EnumTypeDefinitionNode astNode;

  List<EnumValueDefinition> get values =>
      astNode.values.map(EnumValueDefinition.fromNode).toList();

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

  List<InputValueDefinition> get fields =>
      astNode.fields.map(InputValueDefinition.fromNode);

  static InputObjectTypeDefinition fromNode(
          InputObjectTypeDefinitionNode astNode) =>
      InputObjectTypeDefinition(astNode);
}

@immutable
class DirectiveDefinition extends TypeSystemDefinition {
  const DirectiveDefinition(this.astNode);

  @override
  final DirectiveDefinitionNode astNode;

  String get description => astNode.description.value;

  List<InputValueDefinition> get args =>
      astNode.args.map(InputValueDefinition.fromNode);

  List<DirectiveLocation> get locations => astNode.locations;

  bool get repeatable => astNode.repeatable;

  static DirectiveDefinition fromNode(DirectiveDefinitionNode astNode) =>
      DirectiveDefinition(astNode);
}

@immutable
class OperationTypeDefinition extends GraphQLEntity {
  const OperationTypeDefinition(this.astNode);

  @override
  final OperationTypeDefinitionNode astNode;

  OperationType get operation => astNode.operation;
  NamedTypeNode get type => astNode.type;

  static OperationTypeDefinition fromNode(
          OperationTypeDefinitionNode astNode) =>
      OperationTypeDefinition(astNode);
}
