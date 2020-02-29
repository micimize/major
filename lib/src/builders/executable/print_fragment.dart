import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql/src/builders/utils.dart';
import 'package:built_graphql/src/executable/definitions.dart';

String printFragment(FragmentDefinition fragment, PathFocus root) {
  final path = root + fragment.name;

  final fieldClassesTemplate = ListPrinter(
    items: fragment.selectionSet.fields,
    divider: '\n',
  ).map((field) => [printFieldSelectionSet(field, path)]);

  final ss = printSelectionSetFields(fragment.selectionSet, path);
  final built = builtClass(
    (path + 'SelectionSet').className,
    mixins: [path.className],
    implements: [ss.parentClass],
    body: ss.attributes,
  );

  final builder = builderClassFor(
    (path + 'SelectionSet').className,
    implements: [path.className + 'Builder'],
    body: ss.builderAttributes,
  );

  return format('''
    $fieldClassesTemplate

    mixin ${path.className} implements ${ss.parentClass} {
      ${ss.attributes}
    }

    mixin ${path.className}Builder {
      ${ss.builderAttributes}
    }

    $built

    $builder

  ''');
}
