// Contents - Schema-aware overrides of:
// * NamedType
// * InterfaceTypeDefinition
// * ObjectTypeDefinition
// * UnionTypeDefinition
// * ListType
// * InputValueDefinition
// * FieldDefinition
import 'package:meta/meta.dart';
import 'package:gql/ast.dart';

import './schema.dart';
import './definitions/definitions.dart' as d;

mixin SchemaAware on d.GraphQLEntity {}

// TODO will this result in `type is SchemaAware == true`?
mixin SchemaAwareTypeDefinition on d.TypeDefinition implements SchemaAware {}

@immutable
class NamedType extends d.NamedType with SchemaAware {
  NamedType(NamedTypeNode astNode, this.schema) : super(astNode);

  @protected
  final GraphQLSchema schema;

  d.TypeDefinition get type => schema.getType(name);
}

@immutable
class InterfaceTypeDefinition extends d.InterfaceTypeDefinition
    with SchemaAwareTypeDefinition {
  const InterfaceTypeDefinition(
      InterfaceTypeDefinitionNode astNode, this.schema)
      : super(astNode);

  @protected
  final GraphQLSchema schema;

  @override
  List<FieldDefinition> get fields =>
      astNode.fields.map((f) => FieldDefinition(f, schema)).toList();
}

@immutable
class ObjectTypeDefinition extends d.ObjectTypeDefinition
    with SchemaAwareTypeDefinition {
  const ObjectTypeDefinition(ObjectTypeDefinitionNode astNode, this.schema)
      : super(astNode);

  @protected
  final GraphQLSchema schema;

  @override
  List<FieldDefinition> get fields {
    final inherited = _inheritedFieldNames;
    return astNode.fields
        .map((f) => FieldDefinition(
              f,
              schema,
              isOverride: inherited.contains(f.name.value),
            ))
        .toList();
  }

  List<InterfaceTypeDefinition> get interfaces => interfaceNames
      .map((i) => schema.getType(i.name) as InterfaceTypeDefinition)
      .toList();

  Set<String> get _inheritedFieldNames {
    var inherited = <String>{};
    for (final face in interfaces) {
      inherited.addAll(face.fields.map((f) => f.name));
    }
    return inherited;
  }
}

@immutable
class UnionTypeDefinition extends d.UnionTypeDefinition
    with SchemaAwareTypeDefinition {
  const UnionTypeDefinition(UnionTypeDefinitionNode astNode, this.schema)
      : super(astNode);

  @protected
  final GraphQLSchema schema;

  List<SchemaAwareTypeDefinition> get types => typeNames
      .map((t) => schema.getType(t.name) as SchemaAwareTypeDefinition)
      .toList();
}

SchemaAwareTypeDefinition withAwareness(
  TypeDefinition definition,
  GraphQLSchema schema,
) {
  if (definition is d.InterfaceTypeDefinition) {
    return InterfaceTypeDefinition(definition.astNode, schema);
  }
  if (definition is d.ObjectTypeDefinition) {
    return ObjectTypeDefinition(definition.astNode, schema);
  }
  if (definition is d.UnionTypeDefinition) {
    return UnionTypeDefinition(definition.astNode, schema);
  }
  return null;
}

// pass-through types
d.GraphQLType _passThroughAwareness(TypeNode type, GraphQLSchema schema) {
  if (type is NamedTypeNode) {
    return NamedType(type, schema);
  }
  if (type is ListTypeNode) {
    return ListType(type, schema);
  }
  return null;
}

@immutable
class ListType extends d.ListType with SchemaAware {
  ListType(ListTypeNode astNode, this.schema) : super(astNode);

  @protected
  final GraphQLSchema schema;

  @override
  GraphQLType get type =>
      _passThroughAwareness(astNode.type, schema) ?? super.type;
}

@immutable
class InputValueDefinition extends d.InputValueDefinition with SchemaAware {
  InputValueDefinition(InputValueDefinitionNode astNode, this.schema)
      : super(astNode);

  @protected
  final GraphQLSchema schema;

  @override
  GraphQLType get type =>
      _passThroughAwareness(astNode.type, schema) ?? super.type;
}

@immutable
class FieldDefinition extends d.FieldDefinition with SchemaAware {
  const FieldDefinition(
    FieldDefinitionNode astNode,
    this.schema, {
    this.isOverride = false,
  }) : super(astNode);

  @protected
  final GraphQLSchema schema;

  /// Set by [ObjectTypeDefinition] to specify if this field was inhereted from an [InterfaceTypeDefinition]
  final bool isOverride;

  @override
  List<InputValueDefinition> get args =>
      astNode.args.map((arg) => InputValueDefinition(arg, schema)).toList();

  @override
  GraphQLType get type =>
      _passThroughAwareness(astNode.type, schema) ?? super.type;
}
