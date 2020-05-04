import 'dart:async';

import 'package:build/build.dart';
import 'package:major_graphql_generator/src/builders/config.dart';
import 'package:major_graphql_generator/src/builders/utils.dart';
import 'package:gql/schema.dart';
import 'package:meta/meta.dart';
import 'package:major_graphql_generator/src/reader.dart';
import 'package:major_graphql_generator/src/operation.dart';
import 'package:major_graphql_generator/src/builders/executable/print_executable.dart';

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
      printDirectives(
            doc,
            additionalImports: {
              schemaId: null
            }, // '_schema'}, TODO built_value doesn't seem to handle import prefixes
            importBg: true,
          ) +
          '\n' +
          printExecutable(
            ExecutableDocument(
              doc.ast,
              schema.getType,
              doc.importedAsts,
            ),
            modelsFrom(targetAsset),
            doc.imports
                .map(modelsFrom)
                .followedBy([modelsFrom(schemaId)]).toList(),
            //PathFocus.root(),
          )
      //),
      );
}
