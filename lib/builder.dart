import 'dart:async';

import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:built_graphql/src/builders/config.dart';

import './src/builders/schema/builder.dart' show buildSchema;
import './src/builders/executable/builder.dart' show buildExecutable;

BuiltGraphQLBuilder builtGraphQLBuilder(BuilderOptions options) {
  return BuiltGraphQLBuilder(
    schemaId: AssetId.parse(options.config['schema'] as String),
  );
}

class BuiltGraphQLBuilder implements Builder {
  final AssetId schemaId;

  BuiltGraphQLBuilder({
    @required this.schemaId,
  });

  @override
  Map<String, List<String>> get buildExtensions => extensions.forBuild;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    if (schemaId.path == buildStep.inputId.path) {
      return buildSchema(buildStep);
    }
    return buildExecutable(buildStep, schemaId);
  }
}
