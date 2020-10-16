import 'package:built_collection/built_collection.dart';
import 'package:major_graphql_generator/src/builders/config.dart' as config;
import 'package:major_graphql_generator/src/builders/executable/print_inline_in_fragment.dart';
import 'package:major_graphql_generator/src/builders/executable/print_selection_set.dart';
import 'package:major_graphql_generator/src/builders/schema/print_type.dart';
import 'package:major_graphql_generator/src/builders/utils.dart';
import 'package:major_graphql_generator/src/operation.dart';

String printFragmentMixin(
  ExecutableGraphQLEntity source,
  SelectionSet selectionSet,
  PathFocus path, {
  List<Field> additionalFields = const [],
  Iterable<String> additionalInterfaces,
  String additionalBody,
}) {
  if (!shouldGenerate(selectionSet.schemaType.name)) {
    return '';
  }

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

  final schemaClass = className(selectionSet.schemaType.name);

  final parentClass = selectionSetOf(schemaClass);

  final concreteClassName = path.append('SelectionSet').className;

  final builtImplements = BuiltSet<String>(<String>[
    ss.parentClass,
    ...ss.interfaces,
    ...fragmentModelImplementations,
    ...config.configuration.mixinsWhen(
        (selectionSet.fields + additionalFields).map((e) => e.name),
        concreteClassName),
  ]).join(', ');

  final ssFields = (selectionSet.fields + additionalFields).toList();
  final built = builtClass(
    concreteClassName,
    mixins: [path.className],
    fieldNames: ssFields.map((e) => e.name),
    body: '''
    ${builtFactories(
      concreteClassName,
      parentClass,
      schemaClass,
      selectionSet.fields,
      path,
    )}

    ${_concretizeFactory(path.className, concreteClassName, ssFields)}
    
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
          if (!field.type.isNonNull) '@nullable',
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


      static Serializer<${path.className}> get serializer => ${serializerName(path.className)};

    }

    $built


    class ${serializerClassName(path.className)} extends ${serializerClassName(concreteClassName)} {
      @override
      final Iterable<Type> types = const [${path.className}];
    }

    Serializer<${path.className}> ${serializerName(path.className)} = ${serializerClassName(path.className)}();
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

      static ${selectionSetClassName} selectionSet(${className} fragmentInstance) => ${selectionSetClassName}.concretize(fragmentInstance);

      static ${selectionSetClassName}Builder builderFor(${className} fragmentInstance) =>
        selectionSet(fragmentInstance).toBuilder();

      static final fromJson = ${selectionSetClassName}.fromJson;
    ''';

// static ${className} from(${focusClass} focus) => ${selectionSetClassName}.from(focus);

String _concretizeFactory(
  String mixinClassName,
  String concreteClassName,
  Iterable<Field> fields,
) {
  final mappers = ListPrinter(items: fields).map((field) {
    /*
    final type = printBuilderType(
      field.type,
      path: PathFocus.root(field.path),
    );
    */

    return [
      '${dartName(field.alias)}: baseMixin.${dartName(field.alias)}',
      //type.cast('baseMixin.${dartName(field.name)}')
      //printSetter(field.type, field.alias),
    ];
  }).copyWith(divider: ',\n');

  // TODO instead of selectionset -> selectionset, we should do objecttype(selecitonset) or something.
  // TODO maybe .of should take a builder instead
  // factory ${className}.from(${focusClass} focus) => ${className}.of(focus.toObjectBuilder)
  return '''
      factory ${unhide(concreteClassName)}.concretize(${mixinClassName} baseMixin) => _\$${unhide(concreteClassName)}._(
        $mappers
      );
    ''';
}
