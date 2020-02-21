import 'dart:async';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';
import 'package:build/build.dart';

import 'package:gql/ast.dart';
import 'package:gql/language.dart';

const sourceExtension = '.graphql';
const schemaExtension = '.schema.gql.dart';
const astExtension = '.ast.gql.dart';

@immutable
class GraphQLDocument {
  GraphQLDocument({
    @required this.path,
    @required this.imports,
    @required this.ast,
  });

  final String path;
  final List<String> imports;
  final DocumentNode ast;
}

Future<GraphQLDocument> readDocument(
  BuildStep buildStep, [
  AssetId rootId,
]) async {
  final importMap = <String, String>{};
  final seenImports = <String>{};

  final rootAssetId = rootId ?? buildStep.inputId;

  // we need to recursively import the imports of our dependencies,
  // in case they are referenced in our generated types.
  void collectContentRecursivelyFrom(AssetId id) async {
    importMap[id.path] = await buildStep.readAsString(id);
    final segments = id.pathSegments..removeLast();

    final imports = _allRelativeImports(importMap[id.path])
        .map((i) => p.normalize(p.joinAll([...segments, i])))
        .where((i) => !importMap.containsKey(i)) // avoid duplicates/cycles
        .toSet();

    seenImports.addAll(imports);

    final assetIds = await Stream.fromIterable(imports)
        .asyncExpand(
          (relativeImport) => buildStep.findAssets(Glob(relativeImport)),
        )
        .toSet();

    for (final assetId in assetIds) {
      await collectContentRecursivelyFrom(assetId);
    }
  }

  await collectContentRecursivelyFrom(rootAssetId);

  final content = importMap.remove(rootAssetId.path);

  seenImports
      .where(
        (i) => !importMap.containsKey(i),
      )
      .forEach(
        (missing) => log.warning('Could not import missing file $missing.'),
      );

  final path = (rootId ?? buildStep.inputId).path;

  return GraphQLDocument(
    path: path,
    imports: importMap.keys.toList(),
    ast: parseString(content, url: path),
  );
}

/// Collect relative imports from a graphql doc
Set<String> _allRelativeImports(String doc) {
  final imports = <String>{};
  for (final pattern in [
    RegExp(r'^#\s*import\s+"([^"]+)"', multiLine: true),
    RegExp(r"^#\s*import\s+'([^']+)'", multiLine: true)
  ]) {
    pattern.allMatches(doc)?.forEach((m) {
      final path = m?.group(1);
      if (path != null) {
        imports.add(
          path.endsWith(sourceExtension) ? path : '$path$sourceExtension',
        );
      }
    });
  }

  return imports;
}
