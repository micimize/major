import 'package:built_collection/built_collection.dart';
import 'package:built_graphql/src/builders/config.dart' as config;
import 'package:built_graphql/src/builders/executable/print_inline_in_fragment.dart';
import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart';
import 'package:built_graphql/src/executable/selection_simplifier.dart';

String printFragmentMixin(
  ExecutableGraphQLEntity source,
  SelectionSet selectionSet,
  PathFocus path, {
  List<Field> additionalFields = const [],
  Iterable<String> additionalInterfaces,
  String additionalBody,
}) {
  if (selectionSet.inlineFragments?.isNotEmpty ?? false) {
    return printInlineFragmentMixin(
      source,
      selectionSet: selectionSet,
      path: path,
    );
  }

  final fieldMixinsTemplate = ListPrinter(
    items: selectionSet.fields,
    divider: '\n',
  ).map(
    (field) => [
      if (field.selectionSet != null)
        printFragmentMixin(
          field,
          field.selectionSet,
          path + field.alias,
        )
    ],
  );

  final ss = printSelectionSetFields(
    selectionSet,
    path,
    additionalFields: additionalFields,
    additionalInterfaces: additionalInterfaces,
  );

  // TODO pretty major flaw in the serializer collector right now
  // is that it includes all names referenced by the file's path manager
  final fragmentModelImplementations = BuiltSet<String>(selectionSet
      .fragmentPaths
      .map<String>(pathClassName)
      .followedBy(selectionSet.fragmentSpreads.map((e) => className(e.name))));

  final builtImplements = BuiltSet<String>(<String>[
    ss.parentClass,
    ...ss.interfaces,
    ...fragmentModelImplementations,
  ]).join(', ');

  final schemaClass = className(selectionSet.schemaType.name);

  final parentClass = selectionSetOf(schemaClass);
  final concreteClassName = '_${path.className}SelectionSet';

  final built = builtClass(
    concreteClassName,
    mixins: [path.className],
    body: '''
    ${builtFactories(
      concreteClassName,
      parentClass,
      schemaClass,
      selectionSet.fields,
      path,
    )}
    
    ${additionalBody ?? ''}
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

    ${sourceDocBlock(source)}
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
    fragment,
    fragment.selectionSet.simplified(fragment.name),
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
      static ${className} of(${schemaClass} objectType) => ${selectionSetClassName}.of(objectType);
    ''';

// static ${className} from(${focusClass} focus) => ${selectionSetClassName}.from(focus);
