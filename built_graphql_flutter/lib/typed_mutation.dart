import 'package:built_value/built_value.dart';
import 'package:built_graphql_core/built_graphql_core.dart' as bg;
import 'package:gql/ast.dart' show DocumentNode;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/material.dart';

import './common.dart';
import './dev_utils.dart';

typedef TypedRunMutation<Variables, Result> = void Function(
  Variables variables, {
  Result optimisticResult,
});

typedef TypedUpdateCache<Result extends bg.BuiltToJson> = void Function(
  Cache variables,
  TypedQueryResult<Result> queryResult,
);

extension TypedWith on QueryResult {
  TypedQueryResult<Result> typedWith<Result extends bg.BuiltToJson>(
    SerializeFromJson<Result> dataFromJson,
  ) =>
      TypedQueryResult(
        typedData: dataFromJson(data as Map<String, dynamic>),
        exception: exception,
        source: source,
      );
}

/// TODO not the best api
/// Extends [QueryResult] with a `typedData` attribute
class TypedQueryResult<Result extends bg.BuiltToJson> extends QueryResult {
  TypedQueryResult({
    this.typedData,
    OperationException exception,
    bool loading,
    bool optimistic,
    QueryResultSource source,
  }) : super(
          data: typedData.toJson(),
          exception: exception,
          loading: loading,
          optimistic: optimistic,
          source: source,
        );

  Result typedData;

  /*
  @override
  dynamic get data {
    throw Exception('use typedData!');
  }
  */

}

/// A strongly typed version of [MutationBuilder] with
/// * `loading` state
/// * strongly typed result `data`
/// * `exception` (if any)
/// * strongly typed `runMutation` callback
typedef MutationChildBuilder<Data, Variables> = Widget Function({
  bool loading,
  OperationException exception,
  Data data,
  TypedRunMutation<Variables, Data> runMutation,
});

/// A Strongly typed version of [Mutation]
class TypedMutation<Data extends bg.BuiltToJson,
    Variables extends bg.BuiltToJson> extends StatelessWidget {
  TypedMutation({
    @required this.documentNode,
    @required this.builder,
    @required this.dataFromJson,
    this.update,
  });

  /// A strongly typed version of [MutationBuilder] with
  /// * `loading` state
  /// * strongly typed result `data`
  /// * `exception` (if any)
  /// * strongly typed `runMutation` callback
  final MutationChildBuilder<Data, Variables> builder;

  final DocumentNode documentNode;
  final TypedUpdateCache<Data> update;

  final SerializeFromJson<Data> dataFromJson;

  T logErrors<T>(T Function() block) {
    try {
      return block();
    } on BuiltValueNullFieldError catch (e) {
      //print(e.field);
      rethrow;
    }
  }

  static MutationFactory<Result, Variables> factoryFor<
          Result extends bg.BuiltToJson, Variables extends bg.BuiltToJson>({
    @required DocumentNode documentNode,
    @required SerializeFromJson<Result> dataFromJson,
  }) =>
      ({
        @required MutationChildBuilder<Result, Variables> builder,
        TypedUpdateCache<Result> update,
      }) =>
          TypedMutation<Result, Variables>(
            documentNode: documentNode,
            dataFromJson: dataFromJson,
            builder: builder,
            update: update,
          );

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        documentNode: documentNode,
        update: update != null
            ? (cache, result) => update(
                  cache,
                  result.typedWith<Data>(dataFromJson),
                )
            : null,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (RunMutation runMutation, QueryResult result) {
        if (result.hasException) {
          pprint(result.exception.toString());
          pprint(StackTrace.current);
        }

        return builder(
          runMutation: (Variables variables, {Data optimisticResult}) {
            runMutation(
              logErrors(() => variables.toJson()),
              optimisticResult: optimisticResult?.toJson(),
            );
          },
          loading: result.loading,
          exception: result.exception,
          data: result.data != null
              ? logErrors(
                  () => dataFromJson(result.data as Map<String, dynamic>))
              : null,
        );
      },
    );
  }
}

typedef MutationFactory<Result extends bg.BuiltToJson,
        Variables extends bg.BuiltToJson>
    = TypedMutation<Result, Variables> Function({
  @required MutationChildBuilder<Result, Variables> builder,
  TypedUpdateCache<Result> update,
});
