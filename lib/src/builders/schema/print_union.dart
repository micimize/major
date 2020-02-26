import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart';

String printUnion(UnionTypeDefinition unionType) {
  final CLASS_NAME = className(unionType.name);

  final optionsTemplate = ListPrinter(items: unionType.typeNames);

  final GETTERS = optionsTemplate
      .map((option) => [
            '@nullable',
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

  return format('''

    ${docstring(unionType.description, '')}
    /// Union Type of${optionsTemplate.map((o) => [' [${printType(o)}]'])}
    abstract class $CLASS_NAME implements Built<$CLASS_NAME, ${CLASS_NAME}Builder> {

      $CLASS_NAME._();
      factory $CLASS_NAME([void Function(${CLASS_NAME}Builder) updates]) = _\$${CLASS_NAME};

      $GETTERS

      Object get value => $VALUE;

    }

  ''');
}
