import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql/src/builders/utils.dart';
import 'package:built_graphql/src/executable/definitions.dart';

String printFragment(FragmentDefinition fragment) {
  final CLASS_NAME = className(fragment.name);

  final ss = printSelectionSetFields(fragment.selectionSet);
  // TODO materialized selectionset helpers

  return format('''

    mixin $CLASS_NAME on ${ss.parentClass} {
      
      ${ss.attributes}

    }

    mixin ${CLASS_NAME}Builder {

      ${ss.builderAttributes}

    }

  ''');
}
