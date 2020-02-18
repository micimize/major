import 'package:gql/ast.dart' as ast;
import 'package:graphql_schema/graphql_schema.dart' as schema;

class GraphQLSchema extends schema.GraphQLSchema {
  /// The shape which all queries against the backend must take.
  @override
  final schema.GraphQLObjectType queryType;

  /// The shape required for any query that changes the state of the backend.
  @override
  final schema.GraphQLObjectType mutationType;

  /// A [GraphQLObjectType] describing the form of data sent to real-time subscribers.
  ///
  /// Note that as of August 4th, 2018 (when this text was written), subscriptions are not formalized
  /// in the GraphQL specification. Therefore, any GraphQL implementation can potentially implement
  /// subscriptions in its own way.
  @override
  final schema.GraphQLObjectType subscriptionType;

  GraphQLSchema({this.queryType, this.mutationType, this.subscriptionType});
}


GraphQLSchema buildSchema(ast.DocumentNode root) {
  return GraphQLSchema();
}


class TypeVisitor extends ast.RecursiveVisitor {
  Iterable<ast.ObjectTypeDefinitionNode> types = [];

  @override
  visitObjectTypeDefinitionNode(
    ast.ObjectTypeDefinitionNode node,
  ) {
    types = types.followedBy([node]);
    super.visitObjectTypeDefinitionNode(node);
  }
