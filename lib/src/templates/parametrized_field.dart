import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/templates/utils.dart';
import 'package:recase/recase.dart';

final _ARG_MAP = 'BuiltMap<String, Object>';

String _parameterizedField(FieldDefinition field) {
  final FIELD_CLASS_NAME = ReCase(field.name).pascalCase;
  final CLASS_NAME = FIELD_CLASS_NAME + 'Results';

  final argsTemplate = ListPrinter(items: field.args);

  final ARGUMENTS = argsTemplate.braced.map(((arg) => [
        if (arg.type.isNonNull) '@required',
        printType(arg.type),
        dartName(arg.name),
      ]));

  final ARGUMENT_PASSTHROUGH = argsTemplate.map((arg) {
    final name = dartName(arg.name);
    return ['$name: $name'];
  });

  final ARGUMENT_BUILTMAP = argsTemplate.braced.map((arg) {
    final name = dartName(arg.name);
    return [
      // if will throw for required non-nulls
      if (!arg.type.isNonNull)
        'if ($name)',
      "'$name': $name",
    ];
  });

  return '''

    abstract class $CLASS_NAME implements Built<$CLASS_NAME, ${CLASS_NAME}Builder> {

      // static Serializer<FieldResults> get serializer => _\$fieldResultsSerializer;

      $CLASS_NAME._();

      @protected
      BuiltMap<$_ARG_MAP , $FIELD_CLASS_NAME> get results;

      $FIELD_CLASS_NAME operator []($_ARG_MAP args) => results[args];

      factory FieldResults([void Function(${CLASS_NAME}Builder) updates]) =
          _\$${CLASS_NAME};


      static $_ARG_MAP args($ARGUMENTS) => $ARGUMENT_BUILTMAP

      ${CLASS_NAME} call($ARGUMENTS) =>
          results[args($ARGUMENT_PASSTHROUGH)];
    }

  ''';
}

String printField(FieldDefinition field, [FieldDefinition parentField]) {
  if (field.args?.isEmpty ?? true) {
    return '';
  }
  return _parameterizedField(field);
}
