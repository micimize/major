import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart';
import './print_parametrized_field.dart';

String printInterface(
  InterfaceTypeDefinition interfaceType,
  List<ObjectTypeDefinition> possibleTypes,
) {
  final CLASS_NAME = className(interfaceType.name);

  final fieldsTemplate = ListPrinter(items: interfaceType.fields);

  final GETTERS = fieldsTemplate
      .map((field) => [
            docstring(field.name),
            nullable(field.type),
            printType(field.type).type,
            'get',
            dartName(field.name),
          ])
      .semicolons;

  final BUILDER_ATTRS = fieldsTemplate.copyWith(divider: '\n\n').map((field) {
    final type = printBuilderType(field.type);
    return [
      docstring(field.description),
      '${type.type} ${dartName(field.name)};\n',
    ];
  });

  /*
  final factories = ListPrinter(items: possibleTypes.map((o) => o.name)).map(
    (objectClass) => [
      '''
        if (value is $objectClass){
          return $objectClass.of(value);
        }
        '''
    ],
  );

  final ARGUMENTS = fieldsTemplate
      .map((field) => [
            if (field.type.isNonNull) '@required',
            printType(field.type),
            dartName(field.name),
          ])
implements Built<$CLASS_NAME, ${CLASS_NAME}Builder> 

      $CLASS_NAME._();
      factory $CLASS_NAME([void Function(${CLASS_NAME}Builder) updates]) = _\$${CLASS_NAME};
  */
  return format(interfaceType.fields.map(printField).join('') +
      '''
    ${docstring(interfaceType.description, '')}
    @BuiltValue(instantiable: false)
    abstract class $CLASS_NAME<V extends $CLASS_NAME<V, B>, B extends ${CLASS_NAME}Builder<V, B>> extends Built<V, B> {
      $GETTERS
    }

    abstract class ${CLASS_NAME}Builder<V extends $CLASS_NAME<V, B>, B extends ${CLASS_NAME}Builder<V, B>> extends Builder<V, B> {
      $BUILDER_ATTRS
    }
    ''');

  ///abstract class ${CLASS_NAME}Builder {
  ///  $BUILDER_VARIABLES
  ///}
}
