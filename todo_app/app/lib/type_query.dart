import 'package:built_graphql/built_graphql.dart' as bg;
import 'package:gql/ast.dart' show DocumentNode;
import 'package:gql/language.dart' show printNode;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/material.dart';

typedef QueryChildBuilder<Data> = Widget Function({
  bool loading,
  Data data,
  OperationException exception, // should be Exception
});

typedef SerializeFromJson<Data> = Data Function(dynamic json);

class TypedQuery<Data extends bg.BuiltToJson, Variables extends bg.BuiltToJson>
    extends StatelessWidget {
  TypedQuery({
    @required this.documentNode,
    @required this.variables,
    @required this.builder,
    @required this.dataFromJson,
    this.fetchPolicy,
    this.catchLoading = true,
  });

  final QueryChildBuilder<Data> builder;
  final bool catchLoading;
  final SerializeFromJson<Data> dataFromJson;
  final DocumentNode documentNode;
  final FetchPolicy fetchPolicy;
  final Variables variables;

  Data unwrap(QueryResult result) {
    try {
      if (result.data != null) {
        return dataFromJson(result.data);
      }
    } catch (error, stack) {
      print(
          'dataFromJson error when decoding result from ${printNode(documentNode)}!');
      print(error);
      print(stack);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        documentNode: documentNode,
        variables: variables.toJson(),
        fetchPolicy: fetchPolicy,
      ),
      builder: (QueryResult result, {refetch, fetchMore}) {
        if (result.data == null && result.loading && catchLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return builder(
          loading: result.loading,
          exception: result.exception,
          data: unwrap(result),
        );
      },
    );
  }

  static QueryFactory<ResultPayload, Variables> factoryFor<
          ResultPayload extends bg.BuiltToJson,
          Variables extends bg.BuiltToJson>({
    @required DocumentNode documentNode,
    @required SerializeFromJson<ResultPayload> dataFromJson,
  }) =>
      ({
        @required QueryChildBuilder<ResultPayload> builder,
        @required Variables variables,
      }) =>
          TypedQuery<ResultPayload, Variables>(
            documentNode: documentNode,
            dataFromJson: dataFromJson,
            builder: builder,
            variables: variables,
          );
}

// utils for consumers
typedef FromJsonMap<Data> = Data Function(Map<String, Object> json);
typedef FromJsonList<Data> = Data Function(List<dynamic> json);
SerializeFromJson<Data> wrapFromJsonMap<Data>(FromJsonMap<Data> fromMap) {
  return (dynamic json) => json is Map<String, Object> ? fromMap(json) : null;
}

SerializeFromJson<Data> wrapFromJsonList<Data>(FromJsonList<Data> fromList) {
  return (dynamic json) => json is List<dynamic> ? fromList(json) : null;
}

Future<String> keyProviderFactory({
  DocumentNode documentNode,
  Map<String, Object> variables,
}) async =>
    QueryOptions(
      documentNode: documentNode,
      variables: variables,
    ).toKey();

typedef QueryFactory<ResultPayload extends bg.BuiltToJson,
        Variables extends bg.BuiltToJson>
    = TypedQuery<ResultPayload, Variables> Function({
  @required QueryChildBuilder<ResultPayload> builder,
  @required Variables variables,
});
