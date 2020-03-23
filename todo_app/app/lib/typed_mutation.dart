import 'package:built_value/built_value.dart';
import 'package:built_graphql/built_graphql.dart' as bg;
import 'package:gql/ast.dart' show DocumentNode;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/material.dart';
import './dev_utils.dart';

typedef TypedRunMutation<Variables, Result> = void Function(
  Variables variables, {
  Result optimisticResult,
});

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

typedef SerializeFromJson<Data> = Data Function(Map<String, dynamic> jsonMap);
typedef SerializeToJson<Variables> = Map<String, Object> Function(
  Variables json,
);

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
  final OnMutationUpdate update;

  final SerializeFromJson<Data> dataFromJson;

  T logErrors<T>(T Function() block) {
    try {
      return block();
    } on BuiltValueNullFieldError catch (e) {
      // print(e.field);
      rethrow;
    }
  }

  static MutationFactory<ResultPayload, Variables> factoryFor<
          ResultPayload extends bg.BuiltToJson,
          Variables extends bg.BuiltToJson>({
    @required DocumentNode documentNode,
    @required SerializeFromJson<ResultPayload> dataFromJson,
  }) =>
      ({
        @required MutationChildBuilder<ResultPayload, Variables> builder,
        OnMutationUpdate update,
      }) =>
          TypedMutation<ResultPayload, Variables>(
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
        update: update,
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
              optimisticResult: optimisticResult,
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

typedef MutationFactory<ResultPayload extends bg.BuiltToJson,
        Variables extends bg.BuiltToJson>
    = TypedMutation<ResultPayload, Variables> Function({
  @required MutationChildBuilder<ResultPayload, Variables> builder,
  OnMutationUpdate update,
});
