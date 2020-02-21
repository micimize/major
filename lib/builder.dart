import 'dart:async';

import 'package:build/build.dart';
import 'package:built_graphql/src/reader.dart';
import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/templates/schema.dart';
import 'package:dart_style/dart_style.dart';

const sourceExtension = '.graphql';
const schemaExtension = '.schema.gql.dart';
const astExtension = '.ast.gql.dart';

Builder schemaBuilder(BuilderOptions options) => SchemaBuilder();

class SchemaBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        sourceExtension: [schemaExtension],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final doc = await readDocument(buildStep);

    return buildStep.writeAsString(
      buildStep.inputId.changeExtension(schemaExtension),
      _dartfmt.format(printDocument(doc)),
    );
  }
}

final DartFormatter _dartfmt = DartFormatter();

String printDocument(GraphQLDocument document) => '''

${document.imports.map(printImport).join(';\n')}

${printSchema(GraphQLSchema.fromNode(document.ast))}

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
