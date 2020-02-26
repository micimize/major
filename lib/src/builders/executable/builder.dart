import 'dart:async';

import 'package:build/build.dart';
import 'package:built_graphql/src/schema/schema.dart';
import 'package:meta/meta.dart';
import 'package:built_graphql/src/reader.dart';
import 'package:built_graphql/src/executable/executable.dart';
import 'package:built_graphql/src/builders/executable/print_executable.dart';

import 'package:path/path.dart' as p;

const sourceExtension = '.graphql';
const schemaExtension = '.graphql.dart';
const schemaGeneratedExtension = '.graphql.g.dart';
// const astExtension = '.ast.gql.dart';

Builder documentBuilder(BuilderOptions options) {
  return DocumentBuilder(
    schemaId: AssetId.parse(options.config['schema'] as String),
  );
}

class DocumentBuilder implements Builder {
  final AssetId schemaId;

  DocumentBuilder({
    @required this.schemaId,
  });

  @override
  Map<String, List<String>> get buildExtensions => {
        sourceExtension: [schemaExtension],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final schema = GraphQLSchema.fromNode(
      (await readDocument(buildStep, schemaId)).ast,
    );
    final doc = await readDocument(buildStep);
    final targetAsset = buildStep.inputId.changeExtension(schemaExtension);
    final ex = ExecutableDocument(doc.ast, schema.getType);

    return buildStep.writeAsString(
      targetAsset,
      //_dartfmt.format(
      printDocument(
        doc,
        ex,
        generatedPart: p.basenameWithoutExtension(buildStep.inputId.path) +
            schemaGeneratedExtension,
      ),
      //),
    );
  }
}

String printDocument(GraphQLDocument document, ExecutableDocument executable,
        {@required String generatedPart}) =>
    '''
import 'package:built_graphql/built_graphql.dart';

part '${generatedPart}';

${document.imports.map(printImport).join(';\n')}

${printExecutable(executable)}

''';

String printImport(String relativePath) => '${relativePath}.dart';

/*
const libSyntheticExtension = r'$lib$';
const fragmentsFilename = 'fragments.gql.dart';

const genExtension = '.gql.dart';

const opExtension = '.op.gql.dart';
const dataExtension = '.data.gql.dart';
const reqExtension = '.req.gql.dart';
const varExtension = '.var.gql.dart';
const enumExtension = '.enum.gql.dart';
const scalarExtension = '.scalar.gql.dart';
const inputExtension = '.input.gql.dart';
*/
