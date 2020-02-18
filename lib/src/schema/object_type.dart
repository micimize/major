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

  List<InputValueDefinition> get arguments =>
      astNode.args.map(InputValueDefinition.fromNode).toList();

  static FieldDefinition fromNode(FieldDefinitionNode astNode) =>
      FieldDefinition(astNode);
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
