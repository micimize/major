// Contents
// * InterfaceTypeDefinition
// * ObjectTypeDefinition
// * UnionTypeDefinition
part of 'schema.dart';

mixin SchemaAware on GraphQLEntity {}

// TODO will this result in `type is SchemaAware == true`?
mixin SchemaAwareType on TypeDefinition implements SchemaAware {}

@immutable
class _NamedType extends NamedType with SchemaAware {
  _NamedType(NamedTypeNode astNode, this.schema) : super(astNode);

  TypeDefinition get type => schema.getType(name);

  @protected
  final GraphQLSchema schema;
}

@immutable
class InterfaceType extends InterfaceTypeDefinition with SchemaAwareType {
  const InterfaceType(InterfaceTypeDefinitionNode astNode, this.schema)
      : super(astNode);

  @protected
  final GraphQLSchema schema;

  @override
  List<Field> get fields =>
      astNode.fields.map((f) => Field(f, schema)).toList();
}

@immutable
class ObjectType extends ObjectTypeDefinition with SchemaAwareType {
  const ObjectType(ObjectTypeDefinitionNode astNode, this.schema)
      : super(astNode);

  @protected
  final GraphQLSchema schema;

  @override
  List<Field> get fields =>
      astNode.fields.map((f) => Field(f, schema)).toList();

  List<InterfaceType> get interfaces =>
      interfaceNames.map((i) => schema.getType(i.name)).toList();
}

@immutable
class UnionType extends UnionTypeDefinition with SchemaAwareType {
  const UnionType(UnionTypeDefinitionNode astNode, this.schema)
      : super(astNode);

  @protected
  final GraphQLSchema schema;

  List<SchemaAwareType> get types =>
      typeNames.map((t) => schema.getType(t.name)).toList();
}

SchemaAware withAwareness(TypeDefinition definition, GraphQLSchema schema) {
  if (definition is InterfaceTypeDefinition) {
    InterfaceType(definition.astNode, schema);
  }
  if (definition is ObjectTypeDefinition) {
    ObjectType(definition.astNode, schema);
  }
  if (definition is UnionTypeDefinition) {
    UnionType(definition.astNode, schema);
  }
  return null;
}

// pass-through types
GraphQLType _passThroughAwareness(TypeNode type, GraphQLSchema schema) {
  if (type is NamedTypeNode) {
    return _NamedType(type, schema);
  }
  if (type is ListTypeNode) {
    return _ListType(type, schema);
  }
  return null;
}

@immutable
class _ListType extends ListType with SchemaAware {
  _ListType(ListTypeNode astNode, this.schema) : super(astNode);

  @protected
  final GraphQLSchema schema;

  @override
  GraphQLType get type =>
      _passThroughAwareness(astNode.type, schema) ?? super.type;
}

@immutable
class Field extends FieldDefinition with SchemaAware {
  const Field(FieldDefinitionNode astNode, this.schema) : super(astNode);

  @protected
  final GraphQLSchema schema;

  @override
  GraphQLType get type =>
      _passThroughAwareness(astNode.type, schema) ?? super.type;
}
