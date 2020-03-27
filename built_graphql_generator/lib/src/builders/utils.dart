import 'package:build/build.dart' show AssetId;
import 'package:built_collection/built_collection.dart';
import 'package:built_graphql_generator/src/builders/config.dart';
import 'package:built_graphql_generator/src/reader.dart';
import 'package:built_graphql_generator/src/schema/schema.dart'
    show GraphQLType, GraphQLEntity;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:dart_style/dart_style.dart';

/// The prefix the `built_graphql` is imported into generated files as
final bgPrefix = '_bg';

// 1. Stop using "as" when importing "package:built_value/built_value.dart". It prevents the generated code from finding helper methods.
// final builtPrefix = '_bg';

String nullable([GraphQLType type]) =>
    (type != null && type.isNonNull) ? '' : '@nullable';

String keyword(String keyword, Iterable<String> _items) {
  final items = _items.where((i) => i != null);
  return items.isEmpty ? '' : '$keyword ${items.join(", ")}';
}

String _abstractClass(
  String className, {
  Iterable<String> mixins = const [],
  Iterable<String> implements = const [],
  @required String body,
}) =>
    format('''
    abstract class ${className} ${keyword('with', mixins)} ${keyword('implements', implements)} {
      $body
    }
''');

String builtClass(
  String className, {
  Map<String, String> staticFields,
  Iterable<String> mixins = const [],
  Iterable<String> implements = const [],
  @required String body,
  bool serializable,
  @required Iterable<String> fieldNames,
}) {
  /*
  final mainFactory = staticFields == null
      ? 'factory $className([void Function(${className}Builder) updates]) = _\$${unhide(className)};'
      : '''factory $className([void Function(${className}Builder) updates]) => _\$${unhide(className)}((b) => b
        ..update(updates)
        ..${staticFields.entries.map((e) => '${e.key} = ${e.value}').join('\n..')}
      );
      ''';
  */

  final mainFactory =
      'factory $className([void Function(${className}Builder) updates]) = _\$${unhide(className)};';

  final initializeBuilder = staticFields != null
      ? '''
    static void _initializeBuilder(${className}Builder b) => b
      ..${staticFields.entries.map((e) => '${e.key} = ${e.value}').join('\n..')};
      '''
      : '';

  return _abstractClass(
    className,
    mixins: mixins,
    implements: [
      ...implements,
      if (serializable ?? !className.startsWith('_')) '$bgPrefix.BuiltToJson',
      'Built<$className, ${className}Builder>',
      ...configuration.mixinsWhen(fieldNames),
    ],
    body: '''
        $mainFactory
        $className._();

        $initializeBuilder 

        $body

        ${serializable ?? !className.startsWith('_') ? _serializers(className) : ''}
      ''',
  );
}

String sourceDocBlock(GraphQLEntity source) =>
    docstring('```graphql\n${source}\n```');

String _serializers(String className) => '''
    static Serializer<$className> get serializer => ${serializerName(className)};
    static final fromJson = _serializers.curryFromJson(serializer);
    static final _toJson =  _serializers.curryToJson(serializer);
    Map<String, Object> toJson() => _toJson(this);
  ''';

String serializerName(String name) =>
    '_\$' + dartName(unhide(name)) + 'Serializer';

String builderClassFor(
  String className, {
  Iterable<String> mixins = const [],
  Iterable<String> implements = const [],
  @required String body,
}) =>
    _abstractClass(
      className + 'Builder',
      mixins: mixins,
      implements: [
        ...implements,
        'Builder<$className, ${className}Builder>',
      ],
      body: '''
        factory ${className}Builder() = _\$${unhide(className)}Builder;
        ${className}Builder._();

        $body
      ''',
    );

final _dartfmt = DartFormatter();

/// Attempt to format a block
String format(String source) {
  try {
    return _dartfmt.format(source);
  } catch (e) {
    return source;
  }
}

String dartName(String name) => ReCase(name).camelCase;
String className(String name) => ReCase(name).pascalCase;

String unhide(String className) => className.replaceAll(RegExp('^_*'), '');

/// Default class name builder
///
/// TODO: I'm using '' because built_value doesn't escape the conventional $ delimiter,
/// but I don't really like either solution. IMO, generated classes should be named similarly to what a user would name them,
/// and have generated docs that specify their place in the heirachy
String pathClassName(Iterable<String> path) => path.map(className).join('');

typedef GetClassName = String Function(Iterable<String> path);

class ClassNameManager {
  ClassNameManager([this._className = pathClassName]);

  final GetClassName _className;

  final Map<BuiltList<String>, String> _nameRegistry = {};

  Set<String> get usedNames => _nameRegistry.values.toSet();

  String className(Iterable<String> selectionPath) {
    final path = selectionPath.toBuiltList();

    if (_nameRegistry.containsKey(path)) {
      return _nameRegistry[path];
    }
    final defaultName = _className(path);
    final _usedNames = usedNames;
    if (!_usedNames.contains(defaultName)) {
      _nameRegistry[path] = defaultName;
      return defaultName;
    }
    var collision = 2;
    String newName() => _className([defaultName, collision.toString()]);
    while (_usedNames.contains(newName())) {
      collision += 1;
    }
    _nameRegistry[path] = newName();
    return newName();
  }
}

// TODO make the path manager more coherent
class PathFocus {
  PathFocus._(this.manager, Iterable<String> path)
      : path = BuiltList<String>(path);

  PathFocus.root([Iterable<String> path])
      : manager = ClassNameManager(),
        path = BuiltList<String>(path ?? <String>[]);

  final ClassNameManager manager;
  final BuiltList<String> path;

  PathFocus append(String name) => PathFocus._(
        manager,
        path.followedBy([name]),
      );
  PathFocus operator +(Object other) {
    if (other is String) {
      return append(other);
    }
    if (other is Iterable<String>) {
      return PathFocus._(manager, path.followedBy(other));
    }
    if (other is PathFocus) {
      return PathFocus._(manager, path.followedBy(other.path));
    }
    throw StateError(
      'Cannot add ${other.runtimeType} $other to PathFocus $this',
    );
  }

  String get className => manager.className(path);
}

String docstring(String description, [String trailing = '\n']) {
  if (description != null && description.trim().isNotEmpty) {
    return '/// ' + description.trim().split('\n').join('\n/// ') + trailing;
  }
  return '';
}

typedef ItemTemplate<T> = Iterable<String> Function(T item);

/// Templating helper for printing iterables
@immutable
class ListPrinter<T> {
  ListPrinter({
    this.itemTemplate,
    this.items,
    this.spacing = ' ',
    this.divider = ',',
    this.leading = '',
    this.trailing = '',
    this.shouldTrailDivider = _defaultShouldTrailDivider,
  });

  /// Template with which to render [items].
  ///
  /// Each individual result will be joined with [spacing],
  /// and the collective result will be joined with [divider].
  final ItemTemplate<T> itemTemplate;

  /// The items to render
  final Iterable<T> items;

  /// Spacing to add between each item returned by [template]
  final String spacing;

  /// Divider to join the results of [template] on
  final String divider;

  /// Leading prefix for the final result with **if** it is not empty
  final String leading;

  /// Trailing suffix for the final result with **if** it is not empty
  final String trailing;

  /// Determines if the divider should trail
  final bool Function(List<T> items, String innerResults) shouldTrailDivider;

  ListPrinter<T> copyWith({
    ItemTemplate<T> itemTemplate,
    Iterable<T> items,
    String spacing,
    String divider,
    String leading,
    String trailing,
    bool Function(List<T> items, String innerResult) shouldTrailDivider,
  }) =>
      ListPrinter(
        itemTemplate: itemTemplate ?? this.itemTemplate,
        items: items ?? this.items,
        spacing: spacing ?? this.spacing,
        divider: divider ?? this.divider,
        leading: leading ?? this.leading,
        trailing: trailing ?? this.trailing,
        shouldTrailDivider: shouldTrailDivider ?? this.shouldTrailDivider,
      );

  ListPrinter<T> over(Iterable<T> items) => copyWith(items: items);

  ListPrinter<T> map(ItemTemplate<T> itemTemplate) =>
      copyWith(itemTemplate: itemTemplate);

  /// Wraps the printer in { }. alias for `copyWith(leading: '{', trailing: '}')`
  ListPrinter<T> get braced => copyWith(leading: '{', trailing: '}');

  ListPrinter<T> get options => copyWith(leading: '{', trailing: '}');

  /// Alias for `copyWith(divider: ';\n', shouldTrailDivider: (items) => true,);`
  ListPrinter<T> get semicolons => copyWith(
        divider: ';\n',
        shouldTrailDivider: (items, inner) => inner.isNotEmpty,
      );

  /// Adds an extra
  ListPrinter<T> get andDoubleSpaced => copyWith(
        divider: divider.replaceAll('\n', '') + '\n\n',
      );

  //trailingCommaWhen({ int length =  }): (items, inner) => true,

  @override
  String toString() {
    final _items = items.toList();
    var inner =
        _items.map((item) => itemTemplate(item).join(spacing)).join(divider);
    if (shouldTrailDivider(_items, inner)) {
      inner += divider;
    }
    return inner.isEmpty ? inner : '$leading$inner$trailing';
  }
}

bool _defaultShouldTrailDivider(List<Object> items, String inner) => false;

String generatedPartOf(String path) =>
    p.basenameWithoutExtension(path) + extensions.generatedPart;

String adjacentAstFor(String path) =>
    p.basenameWithoutExtension(path) + extensions.generatedAstToAlias;

AssetId dartTargetOf(AssetId assetId) => assetId.changeExtension(
      extensions.dartTarget,
    );

String modelsFrom(AssetId assetId) {
  var segments = assetId.pathSegments;
  var last = segments.removeLast().split('.').first;
  segments.add(last);

  return dartName(segments.join('/')) + 'Models';
}

String moduleSerializers(String serializersUniqueName) => '''

  @SerializersFor(${serializersUniqueName})
  final Serializers serializers = _\$serializers;


  final _serializers = ${bgPrefix}.ConvenienceSerializers(serializers);
''';

String printDirective(AssetId asset,
        {String alias, String directive = 'import', List<String> hide}) =>
    [
      directive,
      "'${dartTargetOf(asset).uri}'",
      if (alias != null) 'as ${alias}',
      if (hide != null && hide.isNotEmpty) 'hide ${hide.join(', ')}',
      ';'
    ].join(' ');

final reExport = true;

String Function(AssetId) printGraphQlDirective(String directive) =>
    (AssetId asset) => printDirective(asset,
        directive: directive, hide: ['serializers', 'document']);

String printDirectives(
  GraphQLDocumentAsset asset, {
  Map<AssetId, String> additionalImports = const {},
  Iterable<String> rawImports = const [],
  Iterable<String> rawExports = const [],
  bool importBg = false,
}) {
  var additional = additionalImports.entries
      .map((imp) => printDirective(imp.key, alias: imp.value))
      .followedBy(rawImports.map((e) => "import '$e';"))
      .followedBy(rawExports.map((e) => "export '$e';"))
      .join('\n');
  if (importBg) {
    additional +=
        "\nimport 'package:built_graphql/built_graphql.dart' as $bgPrefix;";
  }
  return format('''
    /// GENERATED CODE, DO NOT MODIFY BY HAND
    import 'package:meta/meta.dart';
    import 'package:built_collection/built_collection.dart';
    import 'package:built_value/built_value.dart';
    import 'package:built_value/serializer.dart';
    import 'package:built_value/standard_json_plugin.dart';

    ${additional}
    ${asset.imports.map(printGraphQlDirective('import')).join('\n')}

    ${asset.imports.map(printGraphQlDirective('export')).join('\n')}

    export '${adjacentAstFor(asset.path)}' show document;

    part '${generatedPartOf(asset.path)}';

    ''');
}

String selectionSetOf(String schemaClass) =>
    '${bgPrefix}.SelectionSet<$schemaClass, ${schemaClass}Builder>';

final ignoreLints = '// ignore_for_file: ' +
    [
      'always_put_control_body_on_new_line',
      'always_specify_types',
      'annotate_overrides',
      'avoid_annotating_with_dynamic',
      'avoid_as',
      'avoid_catches_without_on_clauses',
      'avoid_returning_this',
      'lines_longer_than_80_chars',
      'omit_local_variable_types',
      'prefer_expression_function_bodies',
      'sort_constructors_first',
      'test_types_in_equals',
      'unnecessary_const',
      'unnecessary_new'
    ].join(',');
