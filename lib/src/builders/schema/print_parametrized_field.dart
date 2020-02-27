import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart';

final _ARG_MAP = 'BuiltMap<String, Object>';

final _seenFields = <String>{};

String _parameterizedField(FieldDefinition field) {
  final FIELD_CLASS_NAME = printType(field.type);

  // only generated field classes once
  if (!_seenFields.add(FIELD_CLASS_NAME)) {
    return '';
  }

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

  final ARGUMENT_BUILTMAP = argsTemplate.map((arg) {
    final name = dartName(arg.name);
    return [
      // if will throw for required non-nulls
      if (!arg.type.isNonNull)
        'if ($name != null)',
      "'$name': $name",
    ];
  });

  final built = builderClassFor(className(field.name) + 'Results', body: '''
      // static Serializer<FieldResults> get serializer => _\$fieldResultsSerializer;

      @${bgPrefix}.protected
      BuiltMap<$_ARG_MAP , $FIELD_CLASS_NAME> get results;

      $FIELD_CLASS_NAME operator []($_ARG_MAP args) => results[args];

      static $_ARG_MAP args($ARGUMENTS) => BuiltMap(<String, Object>{
        $ARGUMENT_BUILTMAP
      });

      $FIELD_CLASS_NAME call($ARGUMENTS) =>
          results[args($ARGUMENT_PASSTHROUGH)];
  ''');

  return format('''

    ${docstring(field.description, '\n///')}
    ${built}
  ''');
}

String printField(FieldDefinition field, [FieldDefinition parentField]) {
  if (field.args?.isEmpty ?? true) {
    return '';
  }
  return _parameterizedField(field);
}
