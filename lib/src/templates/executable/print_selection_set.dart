import 'package:built_graphql/src/executable/definitions.dart';
import 'package:built_graphql/src/templates/schema/print_type.dart';
import 'package:built_graphql/src/templates/utils.dart' as u;

/*
We probably want to define an interface when we're selecting from an interface,
and inheret from it in our concrete object types
*/

String printObjectSelection(String className, SelectionSet selectionSet) {
  final CLASS_NAME = className;
  final SCHEMA_TYPE = u.className(selectionSet.schemaType.name);

  final fieldsTemplate = u.ListPrinter(items: selectionSet.fields);

  final GETTERS = fieldsTemplate
      .copyWith(divider: '\n\n')
      .map((field) => [
            u.docstring(field.schemaType.description),
            if (!field.type.isNonNull) '@nullable',
            printType(field.type),
            'get',
            u.dartName(field.alias),
            '=>',
            '_fields.${u.dartName(field.alias)}'
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
            'set (${printType(field.type)} value)',
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

  return u.format('''

    ${u.docstring(selectionSet.schemaType.description, '')}
    abstract class $CLASS_NAME extends SelectionSetFocus<$SCHEMA_TYPE>
        implements Built<$CLASS_NAME, ${CLASS_NAME}Builder> {
      
      $CLASS_NAME._();
      factory $CLASS_NAME([void Function(${CLASS_NAME}Builder) updates]) = _\$${CLASS_NAME};

      $SCHEMA_TYPE get _fields => unfocus(this);

      $GETTERS

    }

    abstract class ${CLASS_NAME}Builder
        implements Builder<$CLASS_NAME, ${CLASS_NAME}Builder> {

      factory ${CLASS_NAME}Builder() = _\$${CLASS_NAME}Builder;
      ${CLASS_NAME}Builder._();

      ${SCHEMA_TYPE}Builder _fields;

      ${BUILDER_GETTERS}

      ${BUILDER_SETTERS}

    }


  ''');
}
