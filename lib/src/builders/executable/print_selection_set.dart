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

  /// Parent class the [Built] class should `extends` from
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

SelectionSetPrinters printSelectionSetFields(SelectionSet selectionSet) {
  final SCHEMA_TYPE = '_schema.' + u.className(selectionSet.schemaType.name);

  final fieldsTemplate = u.ListPrinter(items: selectionSet.fields);

  final GETTERS = fieldsTemplate
      .copyWith(divider: '\n\n')
      .map((field) => [
            u.docstring(field.schemaType.description),
            u.nullable(field.type),
            printType(field.type),
            'get',
            u.dartName(field.alias),
            '=>',
            '_fields.${u.dartName(field.name)}'
          ])
      .semicolons;

  final BUILDER_GETTERS = fieldsTemplate
      .copyWith(divider: '\n\n')
      .map((field) => [
            u.docstring(field.schemaType.description),
            printType(field.type),
            'get',
            u.dartName(field.alias),
            '=> _fields.${u.dartName(field.name)}',
          ])
      .semicolons;

  final BUILDER_SETTERS = fieldsTemplate
      .copyWith(divider: '\n\n')
      .map((field) => [
            'set ${u.dartName(field.alias)}(${printType(field.type)} value)',
            '=>',
            '_fields.${u.dartName(field.name)} = value',
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
    parentClass: '${u.bgPrefix}.SelectionSetFocus<$SCHEMA_TYPE>',
    attributes: '''
      $SCHEMA_TYPE get _fields => ${u.bgPrefix}.unfocus(this);

      $GETTERS
    ''',
    builderAttributes: '''
      ${SCHEMA_TYPE}Builder _fields;

      ${BUILDER_GETTERS}

      ${BUILDER_SETTERS}
    ''',
  );
}

String printSelectionSetClass({
  @required u.PathFocus path,
  @required String description,
  @required SelectionSet selectionSet,
}) {
  final ss = printSelectionSetFields(selectionSet);

  final built = u.builtClass(
    path.className,
    implements: [ss.parentClass],
    body: ss.attributes,
  );

  final builder = u.builderClassFor(
    path.className,
    body: ss.builderAttributes,
  );

  return u.format('''

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
