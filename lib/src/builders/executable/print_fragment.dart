import 'package:built_graphql/src/builders/config.dart' as config;
import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql/src/builders/utils.dart';
import 'package:built_graphql/src/executable/selection_simplifier.dart';

String printFragment(FragmentDefinition fragment, PathFocus root) {
  final path = root + fragment.name;
  final schemaClass = className(fragment.selectionSet.schemaType.name);
  final schemaBuilderFieldClass =
      config.nestedBuilders ? schemaClass + 'Builder' : schemaClass;

  final selectionSet = fragment.selectionSet.simplified;

  final fieldClassesTemplate = ListPrinter(
    items: selectionSet.fields,
    divider: '\n',
  ).map((field) => [printFieldSelectionSet(field, path)]);

  final ss = printSelectionSetFields(selectionSet.simplified, path);

  final builtImplements = [
    ss.parentClass,
    ...fragment.selectionSet.fragmentSpreads.map(
      (spread) => className(spread.name),
    ),
  ].join(', ');

  final builderImplements = [
    ss.builderParentClass,
    ...fragment.selectionSet.fragmentSpreads.map(
      (spread) => className(spread.name) + 'Builder',
    ),
  ].join(', ');

  final concreteClassName = (path + 'SelectionSet').className;

  final built = builtClass(
    concreteClassName,
    mixins: [path.className],
    // implements: [ss.parentClass],
    body: '''
      ${builtFactories(concreteClassName, ss.parentClass, schemaClass)}

      @override
      ${schemaClass} get ${config.protectedFields};
    ''',
  );

  final builder = builderClassFor(
    concreteClassName,
    mixins: [path.className + 'Builder'],
    body: '''
      @override
      ${schemaBuilderFieldClass} ${config.protectedFields};
    ''', //  the mixin provides fields
  );

  return format('''
    $fieldClassesTemplate

    abstract class ${path.className} implements ${builtImplements} {
      ${ss.attributes}
    }

    abstract class ${path.className}Builder implements ${builderImplements} {
      ${ss.builderAttributes}
    }

    $built

    $builder

  ''');
}
