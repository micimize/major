import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart';

String printUnion(UnionTypeDefinition unionType) {
  final optionsTemplate = ListPrinter(items: unionType.typeNames);

  final GETTERS = optionsTemplate
      .map((option) => [
            nullable(),
            printType(option),
            'get',
            dartName('as ' + option.name),
          ])
      .semicolons;

  final VALUE = optionsTemplate
      .map((option) => [dartName('as ' + option.name)])
      .copyWith(divider: '??');

  /*
  final ARGUMENTS = fieldsTemplate
      .map((field) => [
            if (field.type.isNonNull) '@required',
            printType(field.type),
            dartName(field.name),
          ])
  */

  final built = builtClass(className(unionType.name), body: '''
      $GETTERS

      Object get value => $VALUE;
  ''');

  return format('''

    ${docstring(unionType.description, '')}
    /// Union Type of${optionsTemplate.map((o) => [' [${printType(o)}]'])}
    ${built}
  ''');
}
