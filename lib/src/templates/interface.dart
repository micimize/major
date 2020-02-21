import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/templates/utils.dart';
import './parametrized_field.dart';

String printInterface(InterfaceTypeDefinition interaceType) {
  final CLASS_NAME = className(interaceType.name);

  final fieldsTemplate = ListPrinter(items: interaceType.fields);

  final GETTERS = fieldsTemplate
      .map((field) => [
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

  return interaceType.fields.map(printField).join('') +
      '''

    abstract class $CLASS_NAME implements Built<$CLASS_NAME, ${CLASS_NAME}Builder> {

      $CLASS_NAME._();

      $GETTERS

    }

  ''';
}
