import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql/src/builders/utils.dart';
import 'package:built_graphql/src/executable/definitions.dart';

String printFragment(FragmentDefinition fragment, PathFocus path) {
  final path = PathFocus.root(<String>[fragment.name]);

  final ss = printSelectionSetFields(fragment.selectionSet);
  // TODO materialized selectionset helpers

  return format('''

    mixin ${path.className} on ${ss.parentClass} {
      ${ss.attributes}
    }

    mixin ${path.className}Builder {
      ${ss.builderAttributes}
    }

  ''');
}
