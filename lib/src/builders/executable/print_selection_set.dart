import 'package:built_collection/built_collection.dart';
import 'package:built_graphql/src/builders/config.dart' as config;
import 'package:built_graphql/src/builders/executable/print_inline_fragments.dart';
import 'package:meta/meta.dart';
import 'package:built_graphql/src/executable/selection_simplifier.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart' as u;

@immutable
class SelectionSetPrinters {
  const SelectionSetPrinters({
    @required this.parentClass,
    @required this.interfaces,
    @required this.builderParentClass,
    @required this.attributes,
    @required this.builderAttributes,
  });

  /// Parent class the [Built] class should `implement`
  final String parentClass;

  final BuiltSet<String> interfaces;

  List<String> get allInterfaces => [parentClass, ...interfaces];

  List<String> get allBuilderInterfaces => [
        builderParentClass,
        ...interfaces.map((fragment) => fragment + 'Builder')
      ];

  /// Parent class the [Builder] class should `implement`
  final String builderParentClass;

  /// Attributes that should be added to the [Built] class
  final String attributes;

  /// Attributes that should be added to the [Builder] class
  final String builderAttributes;
}

/*
We probably want to define an interface when we're selecting from an interface,
and inheret from it in our concrete object types
*/

SelectionSetPrinters printSelectionSetFields(
  SelectionSet selectionSet,
  u.PathFocus path, {
  List<Field> additionalFields = const [],
}) {
  final schemaClass = u.className(selectionSet.schemaType.name); // '_schema.' +
  final schemaBuilderFieldClass =
      config.nestedBuilders ? schemaClass + 'Builder' : schemaClass;

  // we use the flattened selectionset fields (i.e. with fragment spreads merged in)
  final fieldsTemplate = u.ListPrinter(
    items: selectionSet.fields + (additionalFields ?? []),
  );

  final GETTERS = fieldsTemplate
      .map((field) {
        final type = printType(field.type, path: path + field.alias);
        return [
          u.docstring(field.schemaType.description),
          if (field.fragmentPaths.isNotEmpty) '@override',
          u.nullable(field.type),
          "@BuiltValueField(wireName: '${field.alias}', serialize: true)",
          type.type,
          'get',
          u.dartName(field.alias),
          '=>',
          type.cast('${config.protectedFields}.${u.dartName(field.name)}')
        ];
      })
      .semicolons
      .andDoubleSpaced;

  final BUILDER_GETTERS = fieldsTemplate
      .map((field) {
        final type = printBuilderType(field.type, path: path + field.alias);
        return [
          u.docstring(field.schemaType.description),
          if (field.fragmentPaths.isNotEmpty) '@override',
          type.type,
          'get',
          u.dartName(field.alias),
          '=>',
          type.cast('${config.protectedFields}.${u.dartName(field.name)}'),
        ];
      })
      .semicolons
      .andDoubleSpaced;

  final BUILDER_SETTERS = fieldsTemplate
      .map((field) {
        final type = printType(field.type, path: path + field.alias);
        return [
          if (field.fragmentPaths.isNotEmpty) '@override',
          'set ${u.dartName(field.alias)}(covariant ${type} value)',
          '=>',
          '${config.protectedFields}.rebuild((f) => f..${u.dartName(field.name)} = ${printSetter(field.type)})',
        ];
      })
      .semicolons
      .andDoubleSpaced;

  return SelectionSetPrinters(
    parentClass: '${u.bgPrefix}.Focus<$schemaClass>',
    interfaces: BuiltSet(<String>[
      ...selectionSet.fragmentPaths.map(path.manager.className),
      ...selectionSet.fragmentSpreads.map((s) => u.className(s.alias)),
    ]),
    builderParentClass: '${u.bgPrefix}.Focus<$schemaBuilderFieldClass>',
    attributes: '''
      @override
      $schemaClass get ${config.protectedFields};

      $GETTERS
    ''',
    builderAttributes: '''
      @override
      @BuiltValueField(serialize: false)
      ${schemaBuilderFieldClass} ${config.protectedFields};

      ${BUILDER_GETTERS}

      ${BUILDER_SETTERS}
    ''',

    /*BUILDER_SETTERS dont think we even need them*/
  );
}

String printSelectionSetClass({
  @required u.PathFocus path,
  @required String description,
  @required SelectionSet selectionSet,
  List<Field> additionalFields = const [],
}) {
  if (selectionSet.inlineFragments?.isNotEmpty ?? false) {
    return printInlineFragments(
      path: path,
      description: description,
      selectionSet: selectionSet,
    );
  }

  final fieldClassesTemplate = u.ListPrinter(
    items: selectionSet.fields,
    divider: '\n\n',
  ).map((field) => [printFieldSelectionSet(field, path)]);

  final schemaType = u.className(selectionSet.schemaType.name); // '_schema.' +

  final ss = printSelectionSetFields(
    selectionSet,
    path,
    additionalFields: additionalFields,
  );

  final built = u.builtClass(
    path.className,
    implements: ss.allInterfaces,
    body: '''
      ${builtFactories(path.className, ss.parentClass, schemaType)}

      ${ss.attributes}
    ''',
  );

  final builder = u.builderClassFor(
    path.className,
    implements: ss.allBuilderInterfaces,
    body: '''
      ${ss.builderAttributes}
    ''',
  );

  return u.format('''
    ${fieldClassesTemplate}

    ${u.docstring(description, '')}
    ${built}

    ${builder}
  ''');
}

String printFieldSelectionSet(Field field, u.PathFocus path) {
  if (field.selectionSet == null) {
    return '';
  }
  return printSelectionSetClass(
    path: path + field.alias,
    description: field.schemaType.description,
    selectionSet: field.selectionSet,
  );
}

String builtFactories(
  String className,
  String focusClass,
  String schemaClass,
) =>
    '''
      factory ${className}.from(${focusClass} focus) => _\$${u.unhide(className)}._(${config.protectedFields}: focus.${config.protectedFields});
      factory ${className}.of(${schemaClass} objectType) => _\$${u.unhide(className)}._(${config.protectedFields}: objectType);
    ''';

/*
  final ARGUMENTS = fieldsTemplate
      .map((field) => [
            if (field.type.isNonNull) '@required',
            printType(field.type),
            dartName(field.name),
          ])
  */
