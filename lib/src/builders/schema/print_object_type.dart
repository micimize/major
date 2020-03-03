import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart';
import 'package:built_graphql/src/builders/schema/print_parametrized_field.dart';

String printObjectType(ObjectTypeDefinition objectType) {
  final fieldsTemplate = ListPrinter(items: objectType.fields);

  final getters = fieldsTemplate
      .copyWith(divider: '\n\n')
      .map((field) => [
            docstring(field.description),
            //nullable(field.type),
            '@nullable',
            if (field.isOverride)
              '@override',
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

  final built = builtClass(
    className(objectType.name),
    implements: objectType.interfaceNames.map((i) => printType(i).type),
    body: getters.toString(),
  );

  return format(objectType.fields.map(printField).join('') +
      '''

    ${docstring(objectType.description, '')}
    ${built}

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
