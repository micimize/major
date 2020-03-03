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
            // nullable(field.type),
            printType(field.type).type,
            'get',
            dartName(field.name),
          ])
      .semicolons;

  final factories = ListPrinter(items: possibleTypes.map((o) => o.name)).map(
    (objectClass) => [
      '''
        if (selectionSet is $selectionSetOf($objectClass)){
          return ${objectClass}Builder();
        }
        '''
    ],
  );

  /*
  final BUILDER_VARIABLES = fieldsTemplate
      .map((field) => [
            docstring(field.name),
            printType(field.type).type,
            dartName(field.name),
          ])
      .semicolons;


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
    abstract class $CLASS_NAME {
      $GETTERS

      $CLASS_NAME rebuild(void Function(${CLASS_NAME}Builder) updates);
      ${CLASS_NAME}Builder toBuilder();

      static ${CLASS_NAME}Builder builderFor(${selectionSetOf(CLASS_NAME)} selectionSet){

        $factories

        throw ArgumentError('No builder for \${selectionSet.runtimeType} \$selectionSet. This should be impossible.');
      }
    }

    /// Add the missing build interface
    extension ${CLASS_NAME}BuilderExt on CharacterBuilder {
      Character build() => null;
    }


    ''');

  ///abstract class ${CLASS_NAME}Builder {
  ///  $BUILDER_VARIABLES
  ///}
}
