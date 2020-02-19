import 'package:meta/meta.dart';
import 'package:gql/ast.dart';
import 'package:gql/language.dart';

part 'base_types.dart';
part 'value_types.dart';
part 'definitions.dart';
part 'defaults.dart';
part 'schema_aware.dart';

@immutable
class GraphQLSchema extends TypeSystemDefinition {
  const GraphQLSchema(
    this.astNode, {
    this.query,
    this.mutation,
    this.subscription,
    this.typeMap,
    this.directives,
  });

  @override
  final SchemaDefinitionNode astNode;

  final List<DirectiveDefinition> directives;

  DirectiveDefinition getDirective(String name) => directives.firstWhere(
        (d) => d.name == name,
        orElse: () => null,
      );

  List<OperationTypeDefinition> get operationTypes =>
      astNode.operationTypes.map(OperationTypeDefinition.fromNode).toList();

  final ObjectTypeDefinition mutation;
  final ObjectTypeDefinition query;
  final ObjectTypeDefinition subscription;

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
  final Map<String, TypeDefinition> typeMap;

  TypeDefinition getType(String name) {
    final type = typeMap[name];
    return withAwareness(type, this) ?? type;
  }

  /*
  List<ObjectTypeDefinition> getPossibleTypes(AbstractType abstractType) =>
      null;

  bool isPossibleType(
          AbstractType abstractType, ObjectTypeDefinition objectType) =>
      false; // objectType is abstractType.runtimeType;
  */

  static GraphQLSchema fromNode(DocumentNode documentNode) =>
      buildSchema(documentNode);
}

/*
 * https://github.com/graphql/graphql-js/blob/49d86bbc810d1203aa3f7d93252e51f257d9460f/src/utilities/buildASTSchema.js#L114
 * 
 * This takes the ast of a schema document produced by the parse function in
 * src/language/parser.js.
 *
 * If no schema definition is provided, then it will look for types named Query
 * and Mutation.
 *
 * Given that AST it constructs a GraphQLSchema. The resulting schema
 * has no resolve methods, so execution will use default resolvers.
 *
 * Accepts options as a second argument:
 *
 *    - commentDescriptions:
 *        Provide true to use preceding comments as the description.
 *
 */
GraphQLSchema buildSchema(
  DocumentNode documentAST,
  //options?: BuildSchemaOptions,
) {
  /*
  if (!options || !(options.assumeValid || options.assumeValidSDL)) {
    assertValidSDL(documentAST);
  }
  */
  SchemaDefinitionNode schemaDef;
  final _typeDefs = <TypeDefinitionNode>[];
  final _directiveDefs = <DirectiveDefinitionNode>[];

  for (final def in documentAST.definitions) {
    if (def is SchemaDefinitionNode) {
      schemaDef = def;
    } else if (def is TypeDefinitionNode) {
      _typeDefs.add(def);
    } else if (def is DirectiveDefinitionNode) {
      _directiveDefs.add(def);
    }
  }
  final typeMap = Map.fromEntries(
    _typeDefs
        .map(TypeDefinition.fromNode)
        .map((type) => MapEntry(type.name, type)),
  );

  final directives = _directiveDefs.map(DirectiveDefinition.fromNode).toList();

  final operationTypeNames = schemaDef != null
      ? getOperationTypeNames(schemaDef)
      : {
          'query': 'Query',
          'mutation': 'Mutation',
          'subscription': 'Subscription',
        };

  // If specified directives were not explicitly declared, add them.
  directives.addAll(missingBuiltinDirectives(directives));

  ObjectTypeDefinition getType(String rootType) {
    final name = operationTypeNames[rootType];
    if (name != null) {
      return typeMap[name] as ObjectTypeDefinition;
    }
    return null;
  }

  return GraphQLSchema(
    schemaDef,
    query: getType('query'),
    mutation: getType('mutation'),
    subscription: getType('subscription'),
    typeMap: typeMap,
    directives: directives,
  );
}

Map<String, String> getOperationTypeNames(SchemaDefinitionNode schema) {
  const opTypes = {};
  for (final operationType in schema.operationTypes) {
    opTypes[operationType.operation] = operationType.type.name.value;
  }
  return opTypes;
}
