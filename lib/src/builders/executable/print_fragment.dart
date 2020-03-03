import 'package:built_graphql/src/builders/config.dart' as config;
import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
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
    ss.builderParentClass ?? 'Object',
    ...selectionSet.fragmentSpreads.map(
      (spread) => className(spread.name) + 'Builder',
    ),
  ].join(', ');

  final schemaClass = className(selectionSet.schemaType.name);
  final schemaBuilderFieldClass =
      config.nestedBuilders ? schemaClass + 'Builder' : schemaClass;

  final parentClass = selectionSetOf(schemaClass);
  final concreteClassName = '_${path.className}SelectionSet';

  final built = builtClass(
    concreteClassName,
    mixins: [path.className],
    body: '''
      ${builtFactories(concreteClassName, parentClass, schemaClass, selectionSet.fields)}
    ''',
  );

  final fieldsTemplate = ListPrinter(items: selectionSet.fields);

  final getters = fieldsTemplate
      .map((field) {
        final type = printType(field.type, path: path + field.alias);
        return [
          docstring(field.schemaType.description),
          if (field.fragmentPaths.isNotEmpty) '@override',
          type.type,
          'get',
          dartName(field.alias),
        ];
      })
      .semicolons
      .andDoubleSpaced;

  return format('''
    $fieldMixinsTemplate

    mixin ${path.className} implements ${builtImplements} {
      ${builtMixinFactories(path.className, concreteClassName, parentClass, schemaClass)}

      ${getters}

      ${toObjectBuilder(selectionSet.schemaType, selectionSet.fields)}
    }

    $built
    ''');
}

String printFragment(FragmentDefinition fragment, PathFocus root) {
  return printFragmentMixin(
    fragment.selectionSet.simplified,
    root + fragment.name,
  );
}

String builtMixinFactories(
  String className,
  String selectionSetClassName,
  String focusClass,
  String schemaClass,
) =>
    '''
      // static ${className} from(${focusClass} focus) => ${selectionSetClassName}.from(focus);
      static ${className} of(${schemaClass} objectType) => ${selectionSetClassName}.of(objectType);
    ''';
