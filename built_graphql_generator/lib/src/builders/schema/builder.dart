import 'dart:async';

import 'package:build/build.dart';
import 'package:built_graphql_generator/src/builders/config.dart';
import 'package:built_graphql_generator/src/builders/utils.dart';
import 'package:built_graphql_generator/src/reader.dart';
import 'package:built_graphql_generator/src/schema/schema.dart';
import 'package:built_graphql_generator/src/builders/schema/print_schema.dart';

class SchemaBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => extensions.forBuild;

  @override
  FutureOr<void> build(BuildStep buildStep) => buildSchema(buildStep);
}

FutureOr<void> buildSchema(BuildStep buildStep) async {
  final doc = await GraphQLDocumentAsset.read(buildStep);

  final targetAsset = buildStep.inputId.changeExtension(
    extensions.dartTarget,
  );
  final dartDirectives = printDirectives(
    doc,
    importBg: true,
    rawImports: configuration.schemaImports,
    rawExports: configuration.schemaExports,
  );

  final schema =
      printSchema(GraphQLSchema.fromNode(doc.ast), modelsFrom(targetAsset));
  return buildStep.writeAsString(
    targetAsset,
    format(
      '''
      $dartDirectives

      $schema
      ''',
    ),
  );
}
