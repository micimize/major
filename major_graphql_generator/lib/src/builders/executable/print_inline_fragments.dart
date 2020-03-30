import 'package:built_collection/built_collection.dart';
import 'package:major_graphql_generator/src/builders/config.dart' as config;
import 'package:major_graphql_generator/src/builders/executable/print_selection_set.dart';
import 'package:meta/meta.dart';
import 'package:major_graphql_generator/src/executable/selection_simplifier.dart';
import 'package:major_graphql_generator/src/builders/schema/print_type.dart';
import 'package:major_graphql_generator/src/builders/utils.dart' as u;

List<String> printInlineFragmentSelectionSet(
  InlineFragment fragment,
  u.PathFocus p, {
  @required List<Field> sharedFields,
  String onGetters,
}) {
  final path = p + fragment.alias;

  return [
    printSelectionSetClass(
      fragment,
      path: path,
      description: fragment.schemaType.description,
      selectionSet: fragment.selectionSet,
      additionalFields: sharedFields,
      additionalInterfaces: [p.className],
      additionalBody: onGetters ?? '',
    )
  ];
}

String printInlineFragments(
  ExecutableGraphQLEntity source, {
  @required u.PathFocus path,
  @required String description,
  @required SelectionSet selectionSet,
}) {
  final schemaClass = u.className(selectionSet.schemaType.name);
  final className = path.className + '';

  final sharedFields = selectionSet.fields ?? [];

  final fragmentsTemplate = u.ListPrinter(
    items: selectionSet.inlineFragments,
  );
  final inlineFragmentClasses = fragmentsTemplate
      .map((fragment) => printInlineFragmentSelectionSet(
            fragment,
            path,
            sharedFields: sharedFields,
            onGetters: fragmentsTemplate
                .map((f) => [
                      '@override',
                      (path + f.alias).className,
                      'get',
                      'on${f.onTypeName}',
                      '=>',
                      fragment == f ? 'this' : 'null',
                    ])
                .semicolons
                .toString(),
          ))
      .copyWith(divider: '\n\n');

  final fragmentAliases = fragmentsTemplate.map((fragment) {
    final _path = path + fragment.alias;
    return [
      _path.className,
      '''get on${fragment.onTypeName} {
          if (this is ${_path.className}){
            return this as ${_path.className};
          }
          return null;
      }'''
    ];
  }).copyWith(divider: '\n\n');

  final objBuilders = fragmentsTemplate
      .map((fragment) => ['on${fragment.onTypeName}?.toObjectBuilder()'])
      .copyWith(divider: ' ?? ');

  final fragmentFactories = fragmentsTemplate.map((fragment) {
    final _path = path + fragment.alias;
    return [
      '''
      if (objectType is ${fragment.onTypeName}){
        return ${_path.className}.of(objectType);
      }
      '''
    ];
  }).copyWith(divider: '\n\n');

  final fieldClassesTemplate = u.ListPrinter(
    items: sharedFields,
    divider: '\n',
  ).map((field) => [printFieldSelectionSet(field, path)]);

  final fieldsTemplate = u.ListPrinter(items: selectionSet.fields);

  final sharedGetters = fieldsTemplate.copyWith(divider: '\n\n').map((field) {
    final type = printType(field.type, path: path + field.alias);
    return [
      u.docstring(field.schemaType.description),
      u.nullable(field.type),
      type.type,
      'get',
      u.dartName(field.alias),
    ];
  }).semicolons;

  final implementations = BuiltSet<String>(<String>[
    '${u.bgPrefix}.BuiltToJson',
    //u.selectionSetOf(schemaClass),
    ...selectionSet.fragmentPaths.map<String>(u.pathClassName),
    ...config.configuration.mixinsWhen(selectionSet.fields.map((e) => e.name)),
  ]).join(', ');

  return u.format('''
    ${inlineFragmentClasses}

    ${fieldClassesTemplate}

    ${u.docstring(description, '')}
    ${u.sourceDocBlock(source)}
    @BuiltValue(instantiable: false)
    abstract class $className implements ${implementations} {

      $className rebuild(void Function(${className}Builder) updates);
      ${className}Builder toBuilder();

      $sharedGetters

      $fragmentAliases

      ${schemaClass}Builder toObjectBuilder() => ${objBuilders};

      static $className of($schemaClass objectType){
        $fragmentFactories

        throw ArgumentError(
          'No concrete inline fragment defined for \${objectType.runtimeType} \$objectType.'
          ' We should have default concrete interface fallbacks... but do not.'
        );
      }

      @BuiltValueSerializer(custom: true)
      static Serializer<$className> get serializer => ${u.bgPrefix}.InterfaceSerializer<$className>(
        wireName: '$schemaClass',
        typeMap: {
          ${fragmentsTemplate.map((f) => [
            "'${f.schemaType.name}':",
            (path + f.alias).className
          ])}},
      );

      static final fromJson = _serializers.curryFromJson(serializer);

      @override
      Map<String, Object> toJson();

    }

    /// Add the missing build interface
    extension ${className}BuilderExt on ${className}Builder {
      Character build() => null;
    }
  ''');
}

String printFieldSelectionSet(Field field, u.PathFocus path) {
  if (field.selectionSet == null) {
    return '';
  }
  return printSelectionSetClass(
    field,
    path: path + field.alias,
    description: field.schemaType.description,
    selectionSet: field.selectionSet,
  );
}
