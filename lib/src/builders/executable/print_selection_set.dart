import 'package:built_graphql/src/builders/executable/print_inline_fragments.dart';
import 'package:meta/meta.dart';
import 'package:built_graphql/src/executable/definitions.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart' as u;

@immutable
class SelectionSetPrinters {
  const SelectionSetPrinters({
    @required this.parentClass,
    @required this.attributes,
    @required this.builderAttributes,
  });

  /// Parent class the [Built] class should `implement`
  final String parentClass;

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
  final SCHEMA_TYPE = u.className(selectionSet.schemaType.name); // '_schema.' +

  final fieldsTemplate = u.ListPrinter(
    items: selectionSet.fields + (additionalFields ?? []),
  );

  final GETTERS = fieldsTemplate.copyWith(divider: '\n\n').map((field) {
    final type = printType(field.type, path: path + field.alias);
    return [
      u.docstring(field.schemaType.description),
      u.nullable(field.type),
      type.type,
      'get',
      u.dartName(field.alias),
      '=>',
      type.cast('\$fields.${u.dartName(field.name)}')
    ];
  }).semicolons;

  final BUILDER_GETTERS = fieldsTemplate.copyWith(divider: '\n\n').map((field) {
    final type = printBuilderType(field.type, path: path + field.alias);
    return [
      u.docstring(field.schemaType.description),
      type.type,
      'get',
      u.dartName(field.alias),
      '=>',
      type.cast('\$fields.${u.dartName(field.name)}'),
    ];
  }).semicolons;

  final BUILDER_SETTERS = fieldsTemplate
      .copyWith(divider: '\n\n')
      .map((field) => [
            'set ${u.dartName(field.alias)}(${printType(field.type, path: path + field.alias)} value)',
            '=>',
            '\$fields.${u.dartName(field.name)} = value',
          ])
      .semicolons;

  /*
  final ARGUMENTS = fieldsTemplate
      .map((field) => [
            if (field.type.isNonNull) '@required',
            printType(field.type),
            dartName(field.name),
          ])
  */
  return SelectionSetPrinters(
    parentClass: '${u.bgPrefix}.Focus<$SCHEMA_TYPE>',
    attributes: '''
      @override
      $SCHEMA_TYPE get \$fields;

      $GETTERS
    ''',
    builderAttributes: '''
      @protected
      ${SCHEMA_TYPE}Builder \$fields;

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
    items: selectionSet.fields,
    divider: '\n',
  ).map((field) => [printFieldSelectionSet(field, path)]);

  final schemaType = u.className(selectionSet.schemaType.name); // '_schema.' +

  final ss = printSelectionSetFields(
    selectionSet,
    path,
    additionalFields: additionalFields,
  );

  final built = u.builtClass(
    path.className,
    implements: [ss.parentClass],
    body: '''
      factory ${path.className}.from(${ss.parentClass} focus) => _\$${path.className}._(\$fields: focus.\$fields);
      factory ${path.className}.of(${schemaType} objectType) => _\$${path.className}._(\$fields: objectType);

      ${ss.attributes}
    ''',
  );

  final builder = u.builderClassFor(
    path.className,
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
