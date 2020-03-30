import 'dart:async';

import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:major_graphql_generator/src/builders/config.dart';

import './src/builders/schema/builder.dart' show buildSchema;
import './src/builders/executable/builder.dart' show buildExecutable;

BuiltGraphQLBuilder builtGraphQLBuilder(BuilderOptions options) {
  configure(options.config);
  return BuiltGraphQLBuilder();
}

class BuiltGraphQLBuilder implements Builder {
  AssetId get schemaId => configuration.schemaId;

  BuiltGraphQLBuilder();

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
