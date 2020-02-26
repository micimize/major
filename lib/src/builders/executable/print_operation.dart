import 'package:built_graphql/built_graphql.dart';
import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql/src/executable/definitions.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart' as u;

String printOperation(OperationDefinition operation) {
  final CLASS_NAME = u.className(operation.name);

  final fieldClassesTemplate = u.ListPrinter(
    items: operation.selectionSet.fields,
    divider: '\n',
  ).map((field) => [printFieldSelectionSet(field)]);

  final operationType = printSelectionSetClass(
    className: CLASS_NAME,
    description: operation.schemaType.description,
    selectionSet: operation.selectionSet,
  );

  return '''
  ${fieldClassesTemplate}

  ${printVariables(CLASS_NAME + 'Variables', operation.variables)}

  ${operationType}
  ''';
}

String printVariables(
    String className, Iterable<VariableDefinition> variables) {
  final CLASS_NAME = className;

  final variablesTemplate = u.ListPrinter(items: variables);

  final GETTERS = variablesTemplate
      .copyWith(divider: '\n\n')
      .map((variable) => [
            if (!variable.schemaType.isNonNull) '@nullable',
            printType(variable.schemaType),
            'get',
            u.dartName(variable.name),
          ])
      .semicolons;

  return u.format('''

    abstract class $CLASS_NAME implements Built<$CLASS_NAME, ${CLASS_NAME}Builder> {
      
      $CLASS_NAME._();
      factory $CLASS_NAME([void Function(${CLASS_NAME}Builder) updates]) = _\$${CLASS_NAME};

      $GETTERS
    }

    ''');
}
