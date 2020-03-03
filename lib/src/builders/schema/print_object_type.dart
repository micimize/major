import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart';
import 'package:built_graphql/src/builders/schema/print_parametrized_field.dart';

String printObjectType(ObjectTypeDefinition objectType) {
  final fieldsTemplate = ListPrinter(items: objectType.fields);

  final getters = fieldsTemplate
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
      .semicolons
      .andDoubleSpaced;

  final builderAttrs = fieldsTemplate
      .map((field) => [
            docstring(field.description),
            if (field.isOverride) '@override',
            printBuilderType(field.type).type,
            dartName(field.name),
          ])
      .semicolons
      .andDoubleSpaced;

  /*
  final ARGUMENTS = fieldsTemplate
      .map((field) => [
            if (field.type.isNonNull) '@required',
            printType(field.type),
            dartName(field.name),
          ])
  */
  final name = className(objectType.name);

  final built = builtClass(
    name,
    implements: objectType.interfaceNames
        .map((i) => printType(i, extending: name).type),
    body: getters.toString(),
  );

  final builder = builderClassFor(
    name,
    implements: objectType.interfaceNames
        .map((i) => printBuilderType(i, extending: name).type),
    body: builderAttrs.toString(),
  );

  return format(objectType.fields.map(printField).join('') +
      '''

    ${docstring(objectType.description, '')}
    ${built}

    ${builder}

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
