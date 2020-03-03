import 'package:meta/meta.dart';

const extensions = _Extensions(
  source: '.graphql',
  dartTarget: '.graphql.dart',
  generatedPart: '.graphql.g.dart',
);

@immutable
class _Extensions {
  const _Extensions({
    @required this.source,
    @required this.dartTarget,
    @required this.generatedPart,
  });

  /// The extension for the implementation part files built_value will generate
  final String generatedPart;

  /// The target extension for the generated dart files
  final String dartTarget;

  /// The source extension for graphql document files
  final String source;

  Map<String, List<String>> get forBuild => {
        extensions.source: [extensions.dartTarget],
      };
}

const nestedBuilders = false;
