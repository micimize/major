import 'package:built_graphql/src/builders/config.dart' as config;
import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql/src/builders/utils.dart';
import 'package:built_graphql/src/executable/selection_simplifier.dart';

String printFragmentMixin(SelectionSet selectionSet, PathFocus path) {
  final fieldMixinsTemplate = ListPrinter(
    items: selectionSet.fields,
    divider: '\n',
  ).map((field) => [
        if (field.selectionSet != null)
          printFragmentMixin(field.selectionSet, path + field.name)
      ]);

  final ss = printSelectionSetFields(selectionSet, path);

  final builtImplements = [
    ss.parentClass,
    ...selectionSet.fragmentSpreads.map(
      (spread) => className(spread.name),
    ),
  ].join(', ');

  final builderImplements = [
    ss.builderParentClass,
    ...selectionSet.fragmentSpreads.map(
      (spread) => className(spread.name) + 'Builder',
    ),
  ].join(', ');

  final schemaClass = className(selectionSet.schemaType.name);
  final schemaBuilderFieldClass =
      config.nestedBuilders ? schemaClass + 'Builder' : schemaClass;

  final parentClass = '${bgPrefix}.Focus<$schemaClass>';
  final concreteClassName = '_${path.className}SelectionSet';

  final built = builtClass(
    concreteClassName,
    mixins: [path.className],
    // implements: [ss.parentClass],
    body: '''
      ${builtFactories(concreteClassName, parentClass, schemaClass)}

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
    $fieldMixinsTemplate

    mixin ${path.className} implements ${builtImplements} {
      ${builtMixinFactories(path.className, concreteClassName, parentClass, schemaClass)}

      ${ss.attributes}
    }

    mixin ${path.className}Builder implements ${builderImplements} {
      ${ss.builderAttributes}
    }

    $built

    $builder
    ''');
}

String printFragment(FragmentDefinition fragment, PathFocus root) {
  return printFragmentMixin(
      fragment.selectionSet.simplified, root + fragment.name);
  /*
  //final path = root + fragment.name;

  final schemaClass = className(selectionSet.schemaType.name);
  final schemaBuilderFieldClass =
      config.nestedBuilders ? schemaClass + 'Builder' : schemaClass;

  final parentClass = '${bgPrefix}.Focus<$schemaClass>';
  final concreteClassName = (path + 'SelectionSet').className;

  final built = builtClass(
    concreteClassName,
    mixins: [path.className],
    // implements: [ss.parentClass],
    body: '''
      ${builtFactories(concreteClassName, parentClass, schemaClass)}

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
    ${printFragmentMixin(fragment.selectionSet.simplified, path)}

    $built

    $builder

  ''');
  */
}

String builtMixinFactories(
  String className,
  String selectionSetClassName,
  String focusClass,
  String schemaClass,
) =>
    '''
      static ${className} from(${focusClass} focus) => ${selectionSetClassName}.from(focus);
      static ${className} of(${schemaClass} focus) => ${selectionSetClassName}.of(focus);
    ''';
