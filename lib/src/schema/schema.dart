import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import "package:meta/meta.dart";

part 'base_types.dart';
part 'value_types.dart';
part 'definitions.dart';
part 'object_type.dart';

class SchemaDefinition extends TypeSystemDefinition {
  ObjectTypeDefinition get mutation => null;
  ObjectTypeDefinition get query => null;
  ObjectTypeDefinition get subscription => null;

  @override
  SchemaDefinitionNode astNode;

  /**
     * These named types do not include modifiers like List or NonNull.
    export type GraphQLNamedType =
      | GraphQLScalarType
      | GraphQLObjectType
      | GraphQLInterfaceType
      | GraphQLUnionType
      | GraphQLEnumType
      | GraphQLInputObjectType;
    */
  Map<String, Object> get typeMap => {};

  Object getType(String name) => null;

  List<ObjectTypeDefinition> getPossibleTypes(AbstractType abstractType) =>
      null;

  bool isPossibleType(
          AbstractType abstractType, ObjectTypeDefinition objectType) =>
      false; // objectType is abstractType.runtimeType;

  List<Directive> get directives => null;

  Directive getDirective(String name) => null;
}
