import 'dart:async';

import 'package:build/build.dart';
import 'package:built_graphql/src/builders/config.dart';
import 'package:built_graphql/src/builders/utils.dart';
import 'package:built_graphql/src/schema/schema.dart';
import 'package:meta/meta.dart';
import 'package:built_graphql/src/reader.dart';
import 'package:built_graphql/src/executable/executable.dart';
import 'package:built_graphql/src/builders/executable/print_executable.dart';

class ExecutableDocumentBuilder implements Builder {
  final AssetId schemaId;

  ExecutableDocumentBuilder({
    @required this.schemaId,
  });

  @override
  Map<String, List<String>> get buildExtensions => extensions.forBuild;

  @override
  FutureOr<void> build(BuildStep buildStep) =>
      buildExecutable(buildStep, schemaId);
}

FutureOr<void> buildExecutable(BuildStep buildStep, AssetId schemaId) async {
  final schema = GraphQLSchema.fromNode(
    (await GraphQLDocumentAsset.read(
      buildStep,
      assetId: schemaId,
      inlineImports: true,
    ))
        .ast,
  );

  final doc = await GraphQLDocumentAsset.read(buildStep);

  final targetAsset = buildStep.inputId.changeExtension(
    extensions.dartTarget,
  );

  return buildStep.writeAsString(
      targetAsset,
      //_dartfmt.format(
      printDirectives(doc, additionalImports: [schemaId.path]) +
          '\n' +
          printExecutable(ExecutableDocument(doc.ast, schema.getType))
      //),
      );
}
