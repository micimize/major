import 'dart:async';

import 'package:built_graphql/src/builders/config.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';
import 'package:build/build.dart';

import 'package:gql/ast.dart';
import 'package:gql/language.dart';

/// A GraphQL Document read from an [AssetId], along with any build-relevant metadata, such as [imports]
///
/// Same concept as https://github.com/gql-dart/gql/blob/df752f577f824c233f33ce0cf31e5d9dc178741a/gql_code_builder/lib/source.dart
@immutable
class GraphQLDocumentAsset {
  GraphQLDocumentAsset(
    this.id, {
    this.imports = const [],
    @required this.ast,
  });

  /// The [AssetId] this document was read from
  final AssetId id;

  /// id.path
  String get path => id.path;

  /// List of recursively collected imports.
  final List<String> imports;

  /// The parsed contents of the document. Does not include import contents
  final DocumentNode ast;

  /// Read a [GraphQLDocumentAsset] from a [BuildStep] and `assetId ?? buildStep.inputId`
  static Future<GraphQLDocumentAsset> read(
    BuildStep buildStep, {
    AssetId assetId,
    bool inlineImports = false,
  }) async {
    final rootAssetId = assetId ?? buildStep.inputId;
    final collector = _ContentCollector(buildStep, rootAssetId);

    // wait for the recursive import collector to crawl all nested imports
    await collector.collectDependencies();

    if (inlineImports) {
      return GraphQLDocumentAsset(
        rootAssetId,
        ast: parseString(
          collector.concatenated,
          url: rootAssetId.path,
        ),
      );
    }

    return GraphQLDocumentAsset(
      rootAssetId,
      imports: collector.imports,
      ast: parseString(
        collector.content,
        url: rootAssetId.path,
      ),
    );
  }
}

class _ContentCollector {
  _ContentCollector(this.buildStep, [this.rootId]);

  final BuildStep buildStep;

  final AssetId rootId;

  /// Map of import paths to content
  final Map<String, String> _importMap = {};

  /// All seen import paths
  final Set<String> _seenImports = {};

  /// Collect all import paths and content.
  ///
  /// We do this recursively to avoid broken references to nested definitions
  void collectDependencies([AssetId id]) async {
    id ??= rootId;
    _importMap[id.path] = await buildStep.readAsString(id);
    final segments = id.pathSegments..removeLast();

    final imports = _allRelativeImports(_importMap[id.path])
        .map((i) => p.normalize(p.joinAll([...segments, i])))
        .where((i) => !_importMap.containsKey(i)) // avoid duplicates/cycles
        .toSet();

    _seenImports.addAll(imports);

    final assetIds = await Stream.fromIterable(imports)
        .asyncExpand(
          (relativeImport) => buildStep.findAssets(Glob(relativeImport)),
        )
        .toSet();

    for (final assetId in assetIds) {
      await collectDependencies(assetId);
    }
  }

  /// Root content
  String get content => _importMap[rootId];

  /// All import and root content concatenated together with blank lines
  String get concatenated => _importMap.values.join('\n\n');

  /// All collected asset paths, excluding the root import
  List<String> get imports {
    final unresolvedImports = _seenImports.where(
      (i) => !_importMap.containsKey(i),
    );

    for (final missing in unresolvedImports) {
      log.warning('Could not import missing file $missing.');
    }

    return _importMap.keys.where((imp) => imp != rootId.path).toList();
  }
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
          path.endsWith(extensions.source) ? path : '$path${extensions.source}',
        );
      }
    });
  }

  return imports;
}
