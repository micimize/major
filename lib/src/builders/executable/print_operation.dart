import 'package:built_graphql/built_graphql.dart';
import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql/src/executable/definitions.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart';

String printOperation(OperationDefinition operation, PathFocus root) {
  final path = root + (operation.name ?? 'Mutation');

  final fieldClassesTemplate = ListPrinter(
    items: operation.selectionSet.fields,
    divider: '\n',
  ).map((field) => [printFieldSelectionSet(field, path)]);

  final operationType = printSelectionSetClass(
    path: path + 'Result',
    description: operation.schemaType.description,
    selectionSet: operation.selectionSet,
  );

  return format('''
  ${fieldClassesTemplate}

  ${printVariables(path + 'Variables', operation.variables)}

  ${operationType}
  ''');
}

String printVariables(
  PathFocus path,
  Iterable<VariableDefinition> variables,
) {
  final variablesTemplate = ListPrinter(items: variables);

  final getters = variablesTemplate
      .copyWith(divider: '\n\n')
      .map((variable) => [
            nullable(variable.schemaType),
            printType(variable.schemaType, prefix: '_schema.'),
            'get',
            dartName(variable.name),
          ])
      .semicolons;

  return builtClass(path.className, body: getters.toString());
}
