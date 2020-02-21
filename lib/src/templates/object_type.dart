import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/templates/print_type.dart';
import 'package:built_graphql/src/templates/utils.dart';
import './parametrized_field.dart';

String printObjectType(ObjectTypeDefinition objectType) {
  final CLASS_NAME = className(objectType.name);

  final fieldsTemplate = ListPrinter(items: objectType.fields);

  final interfaceTemplate = ListPrinter(
    items: objectType.interfaceNames,
    itemTemplate: (GraphQLType name) => [printType(name)],
    trailing: ', ',
  );

  final GETTERS = fieldsTemplate
      .copyWith(divider: '\n\n')
      .map((field) => [
            docstring(field.description),
            if (!field.type.isNonNull) '@nullable',
            if (field.isOverride) '@override',
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

  return format(objectType.fields.map(printField).join('') +
      '''

    ${docstring(objectType.description, '')}
    abstract class $CLASS_NAME implements ${interfaceTemplate}Built<$CLASS_NAME, ${CLASS_NAME}Builder> {

      $CLASS_NAME._();
      factory $CLASS_NAME([void Function(${CLASS_NAME}Builder) updates]) = _\$${CLASS_NAME};

      $GETTERS

    }

  ''');
}

/*

abstract class FieldResults<Result>
    implements Built<FieldResults<Result>, FieldResultsBuilder<Result>> {
  // static Serializer<FieldResults> get serializer => _$fieldResultsSerializer;
  FieldResults._();

  @protected
  BuiltMap<BuiltMap<String, Object>, Result> get results;

  Result operator [](BuiltMap<String, Object> args) => results[args];

  factory FieldResults([void Function(FieldResultsBuilder) updates]) =
      _$FieldResults<Result>;


  static BuiltMap<String, Object> args({
    Episode episode,
  }) => {
        // only for optionals
        if (episode != null)
          'episode': episode,
      }

  Character call({
    Episode episode,
  }) =>
      results[args(
          episode: episode 
      )];
}

*/
