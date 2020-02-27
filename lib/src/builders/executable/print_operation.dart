import 'package:built_graphql/built_graphql.dart';
import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql/src/executable/definitions.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart' as u;

String printOperation(OperationDefinition operation) {
  final CLASS_NAME = u.className(operation.name ?? 'Mutation');

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
  final variablesTemplate = u.ListPrinter(items: variables);

  final getters = variablesTemplate
      .copyWith(divider: '\n\n')
      .map((variable) => [
            if (!variable.schemaType.isNonNull) '@nullable',
            printType(variable.schemaType),
            'get',
            u.dartName(variable.name),
          ])
      .semicolons;

  return u.builtClass(className, body: getters.toString());
}
