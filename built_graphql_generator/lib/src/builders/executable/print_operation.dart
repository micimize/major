import 'package:built_graphql_generator/built_graphql_generator.dart';
import 'package:built_graphql_generator/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql_generator/src/executable/definitions.dart';
import 'package:built_graphql_generator/src/executable/selection_simplifier.dart'
    show GetSimplified;
import 'package:built_graphql_generator/src/builders/schema/print_type.dart';
import 'package:built_graphql_generator/src/builders/utils.dart';

String printOperation(OperationDefinition operation, PathFocus root) {
  final path = root + (operation.name ?? 'Mutation');

  final operationType = printSelectionSetClass(
    operation,
    path: path + 'Result',
    description: operation.schemaType.description,
    selectionSet: operation.selectionSet.simplified(
      (path + 'Result').className,
    ),
  );

  return format('''
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
            printType(variable.schemaType).type, //, prefix: '_schema.'),
            'get',
            dartName(variable.name),
          ])
      .semicolons;

  return builtClass(
    path.className,
    body: getters.toString(),
    fieldNames: variables.map((e) => e.name),
  );
}
