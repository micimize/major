// Contents:
// * FieldDefinition
// * ScalarTypeDefinition
// * InputValueDefinition
// * EnumTypeDefinition
// * EnumValueDefinition
// * InputObjectTypeDefinition
// * DirectiveDefinition
// * InterfaceTypeDefinition
// * ObjectTypeDefinition
// * UnionTypeDefinition
import 'package:meta/meta.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';

part 'base_types.dart';
part 'value_types.dart';

/// Callback to dereference a type name into it's material version
typedef ResolveType = TypeDefinition Function(String name);

abstract class TypeResolver {
  @protected
  ResolveType get getType;

  static TypeDefinition withoutContext(String name) => throw StateError(
      'Cannot resolve type $name in a context without a type resolver!');
}

@immutable
class FieldDefinition extends GraphQLEntity implements TypeResolver {
  const FieldDefinition(
    this.astNode, [
    ResolveType getType,
  ]) : getType = getType ?? TypeResolver.withoutContext;

  @override
  final ResolveType getType;

  @override
  final FieldDefinitionNode astNode;

  String get name => astNode.name.value;

  String get description => astNode.description?.value;

  GraphQLType get type => GraphQLType.fromNode(astNode.type);

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

  String get name => astNode.name.value;

  String get description => astNode.description?.value;

  GraphQLType get type => GraphQLType.fromNode(astNode.type);

  Value get defaultValue => Value.fromNode(astNode.defaultValue);

  List<Directive> get directives =>
      astNode.directives.map(Directive.fromNode).toList();

  static InputValueDefinition fromNode(InputValueDefinitionNode astNode) =>
      InputValueDefinition(astNode);
}

@immutable
class InterfaceTypeDefinition extends TypeDefinition
    with AbstractType
    implements TypeResolver {
  const InterfaceTypeDefinition(
    this.astNode, [
    ResolveType getType,
  ]) : getType = getType ?? TypeResolver.withoutContext;

  @override
  final ResolveType getType;

  @override
  List<FieldDefinition> get fields =>
      astNode.fields.map((f) => FieldDefinition(f, schema)).toList();

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

  List<NamedType> get interfaceNames =>
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

  List<NamedType> get typeNames =>
      astNode.types.map(NamedType.fromNode).toList();

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
      astNode.fields.map(InputValueDefinition.fromNode).toList();

  static InputObjectTypeDefinition fromNode(
          InputObjectTypeDefinitionNode astNode) =>
      InputObjectTypeDefinition(astNode);
}

@immutable
class DirectiveDefinition extends TypeSystemDefinition {
  const DirectiveDefinition(this.astNode);

  @override
  final DirectiveDefinitionNode astNode;

  String get description => astNode.description?.value;

  List<InputValueDefinition> get args =>
      astNode.args.map(InputValueDefinition.fromNode).toList();

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

  NamedType get type => NamedType.fromNode(astNode.type);

  static OperationTypeDefinition fromNode(
          OperationTypeDefinitionNode astNode) =>
      OperationTypeDefinition(astNode);
}
