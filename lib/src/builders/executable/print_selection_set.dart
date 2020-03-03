import 'package:built_collection/built_collection.dart';
import 'package:built_graphql/src/builders/config.dart' as config;
import 'package:built_graphql/src/builders/executable/print_inline_fragments.dart';
import 'package:meta/meta.dart';
import 'package:built_graphql/src/executable/selection_simplifier.dart';
import 'package:built_graphql/src/schema/schema.dart' as s;
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart' as u;

@immutable
class SelectionSetPrinters {
  const SelectionSetPrinters({
    @required this.parentClass,
    @required this.interfaces,
    this.builderParentClass,
    @required this.attributes,
    @required this.builderAttributes,
  });

  /// Parent class the [Built] class should `implement`
  final String parentClass;

  final BuiltSet<String> interfaces;

  List<String> get allInterfaces => [parentClass, ...interfaces];

  List<String> get allBuilderInterfaces => [
        if (builderParentClass != null) builderParentClass,
        ...interfaces.map((fragment) => fragment + 'Builder')
      ];

  /// Parent class the [Builder] class should `implement`
  final String builderParentClass;

  /// Attributes that should be added to the [Built] class
  final String attributes;

  /// Attributes that should be added to the [Builder] class
  final String builderAttributes;
}

/*
We probably want to define an interface when we're selecting from an interface,
and inheret from it in our concrete object types
*/

SelectionSetPrinters printSelectionSetFields(
  SelectionSet selectionSet,
  u.PathFocus path, {
  List<Field> additionalFields = const [],
  Iterable<String> additionalInterfaces,
}) {
  final schemaClass = u.className(selectionSet.schemaType.name); // '_schema.' +
  final schemaBuilderFieldClass =
      config.nestedBuilders ? schemaClass + 'Builder' : schemaClass;

  final fields = selectionSet.fields + (additionalFields ?? []);
  // we use the flattened selectionset fields (i.e. with fragment spreads merged in)
  final fieldsTemplate = u.ListPrinter(items: fields);

  final GETTERS = fieldsTemplate
      .map((field) {
        final type = printType(field.type, path: path + field.alias);
        return [
          u.docstring(field.schemaType.description),
          if (field.fragmentPaths.isNotEmpty) '@override',
          u.nullable(field.type),
          "@BuiltValueField(wireName: '${field.alias}', serialize: true)",
          type.type,
          'get',
          u.dartName(field.alias),
        ];
      })
      .semicolons
      .andDoubleSpaced;

  return SelectionSetPrinters(
    parentClass: u.selectionSetOf(schemaClass),
    interfaces: BuiltSet(<String>[
      ...(additionalInterfaces ?? []),
      ...selectionSet.fragmentPaths.map(path.manager.className),
      ...selectionSet.fragmentSpreads.map((s) => u.className(s.alias)),
    ]),
    attributes: '''
      $GETTERS

      ${toObjectBuilder(selectionSet.schemaType, fields)}
    ''',
    builderAttributes: '''
    ''',
  );
}

String printSelectionSetClass({
  @required u.PathFocus path,
  @required String description,
  @required SelectionSet selectionSet,
  List<Field> additionalFields = const [],
  List<String> additionalInterfaces,
  String additionalBody = '',
}) {
  if (selectionSet.inlineFragments?.isNotEmpty ?? false) {
    return printInlineFragments(
      path: path,
      description: description,
      selectionSet: selectionSet,
    );
  }

  final fieldClassesTemplate = u.ListPrinter(
    items: selectionSet.fields,
    divider: '\n\n',
  ).map((field) => [printFieldSelectionSet(field, path)]);

  final schemaType = u.className(selectionSet.schemaType.name); // '_schema.' +

  final ss = printSelectionSetFields(
    selectionSet,
    path,
    additionalFields: additionalFields,
    additionalInterfaces: additionalInterfaces,
  );

  final built = u.builtClass(
    path.className,
    implements: ss.allInterfaces,
    body: '''
      ${builtFactories(
      path.className,
      ss.parentClass,
      schemaType,
      selectionSet.fields + (additionalFields ?? []),
      path,
    )}

      ${ss.attributes}
      ${additionalBody}
    ''',
  );

  final builder = u.builderClassFor(
    path.className,
    implements: ss.allBuilderInterfaces,
    body: '''
      ${ss.builderAttributes}
    ''',
  );

  return u.format('''
    ${fieldClassesTemplate}

    ${u.docstring(description, '')}
    ${built}

  ''');
  //${builder}
}

String printFieldSelectionSet(Field field, u.PathFocus path) {
  if (field.selectionSet == null) {
    return '';
  }
  return printSelectionSetClass(
    path: path + field.alias,
    description: field.schemaType.description,
    selectionSet: field.selectionSet,
  );
}

String builtFactories(
  String className,
  String focusClass,
  String schemaClass,
  List<Field> fields,
  u.PathFocus path,
) {
  final mappers = u.ListPrinter(items: fields).map((field) {
    final type = printBuilderType(field.type, path: path + field.alias);

    return [
      '${u.dartName(field.alias)}:',
      type.cast('objectType.${u.dartName(field.name)}')
      //printSetter(field.type, field.alias),
    ];
  }).copyWith(divider: ',\n');

  // TODO instead of selectionset -> selectionset, we should do objecttype(selecitonset) or something.
  // TODO maybe .of should take a builder instead
  // factory ${className}.from(${focusClass} focus) => ${className}.of(focus.toObjectBuilder)
  return '''
      factory ${className}.of(${schemaClass} objectType) => _\$${u.unhide(className)}._(
        $mappers
      );
    ''';
}

/*
  final ARGUMENTS = fieldsTemplate
      .map((field) => [
            if (field.type.isNonNull) '@required',
            printType(field.type),
            dartName(field.name),
          ])
  */

/// Get the object type builder from the schema,
/// allowing interface builders to resolve to one of their possible concrete type builders
String toObjectBuilder(
  s.TypeDefinition schemaType,
  List<Field> fields,
) {
  final schemaClass = u.className(schemaType.name);
  final getBuilder = '${schemaClass}' +
      (schemaType is s.InterfaceTypeDefinition
          ? '.builderFor(this)'
          : 'Builder()');
  final setters = u.ListPrinter(items: fields).map((field) {
    return [
      '..${u.dartName(field.name)} =',
      printObjTypeSetter(field.type, field.alias),
    ];
  }).copyWith(divider: '\n');
  return '''
    @override
    ${schemaClass}Builder toObjectBuilder() => ${getBuilder}
      ${setters};
    ''';
}
