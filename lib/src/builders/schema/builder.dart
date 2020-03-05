import 'dart:async';

import 'package:build/build.dart';
import 'package:built_graphql/src/builders/config.dart';
import 'package:built_graphql/src/builders/utils.dart';
import 'package:built_graphql/src/reader.dart';
import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/builders/schema/print_schema.dart';

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

  return buildStep.writeAsString(
      targetAsset,
      //_dartfmt.format(
      printDirectives(doc, importBg: true) +
          '\n' +
          printSchema(GraphQLSchema.fromNode(doc.ast), modelsFrom(targetAsset))
      //),
      );
}
