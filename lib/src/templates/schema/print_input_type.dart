import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/templates/schema/print_type.dart';
import 'package:built_graphql/src/templates/utils.dart';

String printInputObjectType(InputObjectTypeDefinition inputType) {
  final CLASS_NAME = className(inputType.name);

  final fieldsTemplate = ListPrinter(items: inputType.fields);

  /*
  final interfaceTemplate = ListPrinter(
    items: inputType.interfaceNames,
    itemTemplate: (GraphQLType name) => [printType(name)],
    trailing: ', ',
  );
  */

  final GETTERS = fieldsTemplate
      .map((field) => [
            docstring(field.name),
            if (!field.type.isNonNull) '@nullable',
            printType(field.type),
            'get',
            dartName(field.name),
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

  return format('''

    ${docstring(inputType.description, '')}
    abstract class $CLASS_NAME implements Built<$CLASS_NAME, ${CLASS_NAME}Builder> {

      $CLASS_NAME._();
      factory $CLASS_NAME([void Function(${CLASS_NAME}Builder) updates]) = _\$${CLASS_NAME};

      $GETTERS

    }

  ''');
}
