import 'package:built_collection/built_collection.dart';
import 'package:built_graphql/src/builders/config.dart' as config;
import 'package:built_graphql/src/builders/executable/print_fragment.dart';
import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:meta/meta.dart';
import 'package:built_graphql/src/executable/selection_simplifier.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart' as u;

List<String> printInlineFragmentSelectionSetMixin(
  InlineFragment fragment,
  u.PathFocus p, {
  @required List<Field> sharedFields,
  String onGetters,
}) {
  final path = p + fragment.alias;

  return [
    // will tail recurse into printInlineFragmentMixin if nested inline fragments found
    printFragmentMixin(
      fragment,
      fragment.selectionSet,
      path,
      additionalFields: sharedFields,
      additionalInterfaces: [p.className],
      additionalBody: onGetters ?? '',
    )
  ];
}

String printInlineFragmentMixin(
  ExecutableGraphQLEntity source, {
  @required u.PathFocus path,
  @required SelectionSet selectionSet,
}) {
  final schemaClass = u.className(selectionSet.schemaType.name);
  final className = path.className + '';

  final sharedFields = selectionSet.fields ?? [];

  final fragmentsTemplate = u.ListPrinter(
    items: selectionSet.inlineFragments,
  );
  final inlineFragmentClasses = fragmentsTemplate
      .map((fragment) => printInlineFragmentSelectionSetMixin(
            fragment,
            path,
            sharedFields: sharedFields,
            onGetters: fragmentsTemplate
                .map((f) => [
                      '@override',
                      (path + f.alias).className,
                      'get',
                      f.alias,
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

  final fieldClassesTemplate = u.ListPrinter(
    items: sharedFields,
    divider: '\n',
  ).map((field) => [
        if (field.selectionSet != null)
          printFragmentMixin(field, field.selectionSet, path + field.alias)
      ]);

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

  // inline fragments are selectionsets of interfaces
  //final parentClass = u.selectionSetOf(schemaClass);

  final implementations = BuiltSet<String>(<String>[
    // '${u.bgPrefix}.BuiltToJson',
    //parentClass,
    ...selectionSet.fragmentPaths.map<String>(u.pathClassName),
    ...config.configuration.mixinsWhen(selectionSet.fields.map((e) => e.name)),
  ]).join(', ');

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

  return u.format('''
    ${inlineFragmentClasses}

    ${fieldClassesTemplate}

    /// Inline Fragment Base Mixin
    ${u.sourceDocBlock(source)}
    mixin $className ${(implementations.isNotEmpty) ? 'implements' : ''} ${implementations} {

      static $className of($schemaClass objectType){
        $fragmentFactories

        throw ArgumentError(
          'No concrete inline fragment defined for \${objectType.runtimeType} \$objectType.'
          ' We should have default concrete interface fallbacks... but do not.'
        );
      }

      $sharedGetters

      $fragmentAliases

      ${schemaClass}Builder toObjectBuilder();

    }

  ''');
}
