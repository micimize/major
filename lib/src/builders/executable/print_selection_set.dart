import 'package:built_graphql/src/builders/config.dart' as config;
import 'package:built_graphql/src/builders/executable/print_inline_fragments.dart';
import 'package:meta/meta.dart';
import 'package:built_graphql/src/executable/definitions.dart';
import 'package:built_graphql/src/schema/definitions.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart' as u;

@immutable
class SelectionSetPrinters {
  const SelectionSetPrinters({
    @required this.parentClass,
    @required this.allFragments,
    @required this.builderParentClass,
    @required this.attributes,
    @required this.builderAttributes,
  });

  /// Parent class the [Built] class should `implement`
  final String parentClass;

  final List<String> allFragments;

  List<String> get allInterfaces => [
        parentClass,
        ...allFragments.map(u.className),
      ];

  List<String> get allBuilderInterfaces => [
        builderParentClass,
        ...allFragments.map((fragment) => u.className(fragment) + 'Builder')
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

  final flattened = selectionSet.flattened;

  // we use the flattened selectionset fields (i.e. with fragment spreads merged in)
  final fieldsTemplate = u.ListPrinter(
    items: flattened.fields + (additionalFields ?? []),
  );

  final GETTERS = fieldsTemplate
      .map((field) {
        final type = printType(field.type, path: path + field.alias);
        return [
          u.docstring(field.schemaType.description),
          u.nullable(field.type),
          if (field.flattened) '@override',
          type.type,
          'get',
          u.dartName(field.alias),
          '=>',
          type.cast('${config.protectedFields}.${u.dartName(field.name)}')
        ];
      })
      .semicolons
      .andDoubleSpaced;

  final BUILDER_GETTERS = fieldsTemplate.copyWith(divider: '\n\n').map((field) {
    final type = printBuilderType(field.type, path: path + field.alias);
    return [
      u.docstring(field.schemaType.description),
      type.type,
      'get',
      u.dartName(field.alias),
      '=>',
      type.cast('${config.protectedFields}.${u.dartName(field.name)}'),
    ];
  }).semicolons;

  /*
  final BUILDER_SETTERS = fieldsTemplate
      .copyWith(divider: '\n\n')
      .map((field) => [
            'set ${u.dartName(field.alias)}(${printType(field.type, path: path + field.alias)} value)',
            '=>',
            '${config.protectedFields}.${u.dartName(field.name)} = value',
          ])
      .semicolons;

  final ARGUMENTS = fieldsTemplate
      .map((field) => [
            if (field.type.isNonNull) '@required',
            printType(field.type),
            dartName(field.name),
          ])
  */
  return SelectionSetPrinters(
    parentClass: '${u.bgPrefix}.Focus<$schemaClass>',
    allFragments: flattened.fragmentSpreadNames,
    builderParentClass: '${u.bgPrefix}.Focus<$schemaBuilderFieldClass>',
    attributes: '''
      @override
      $schemaClass get ${config.protectedFields};

      $GETTERS
    ''',
    builderAttributes: '''
      @override
      ${schemaBuilderFieldClass} ${config.protectedFields};

      ${BUILDER_GETTERS}
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
    items: selectionSet.flattened.fields,
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
      factory ${className}.from(${focusClass} focus) => _\$${className}._(${config.protectedFields}: focus.${config.protectedFields});
      factory ${className}.of(${schemaClass} objectType) => _\$${className}._(${config.protectedFields}: objectType);
    ''';
