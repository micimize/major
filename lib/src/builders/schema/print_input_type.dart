import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart';

String printInputObjectType(InputObjectTypeDefinition inputType) {
  final fieldsTemplate = ListPrinter(items: inputType.fields);

  /*
  final interfaceTemplate = ListPrinter(
    items: inputType.interfaceNames,
    itemTemplate: (GraphQLType name) => [printType(name)],
    trailing: ', ',
  );
  */

  final getters = fieldsTemplate
      .map((field) => [
            docstring(field.name),
            nullable(field.type),
            printType(field.type).type,
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

  final built = builtClass(className(inputType.name), body: getters.toString());

  return format('''

    ${docstring(inputType.description, '')}
    ${built}
  ''');
}
