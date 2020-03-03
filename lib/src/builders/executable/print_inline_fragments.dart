import 'package:built_graphql/src/builders/config.dart' as config;
import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:meta/meta.dart';
import 'package:built_graphql/src/executable/selection_simplifier.dart';
import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/builders/utils.dart' as u;

List<String> printInlineFragmentSelectionSet(
  InlineFragment fragment,
  u.PathFocus p, {
  @required List<Field> sharedFields,
}) {
  final path = p + 'on' + fragment.onTypeName;

  return [
    printSelectionSetClass(
      path: path,
      description: fragment.schemaType.description,
      selectionSet: fragment.selectionSet,
      additionalFields: sharedFields,
    )
  ];
}

String printInlineFragments({
  @required u.PathFocus path,
  @required String description,
  @required SelectionSet selectionSet,
}) {
  final schemaClass = u.className(selectionSet.schemaType.name);
  final ssClass = u.selectionSetOf(schemaClass);

  final sharedFields = selectionSet.fields ?? [];

  final fragmentsTemplate = u.ListPrinter(
    items: selectionSet.inlineFragments,
  );

  final inlineFragmentClasses = fragmentsTemplate
      .map(
        (fragment) => printInlineFragmentSelectionSet(
          fragment,
          path,
          sharedFields: sharedFields,
        ),
      )
      .copyWith(divider: '\n\n');

  final fragmentAliases = fragmentsTemplate.map((fragment) {
    final _path = path + fragment.alias;
    return [
      _path.className,
      '''get on${fragment.onTypeName} {
          final _value  = value;
          return _value is ${_path.className} ? _value : null;
      }'''
    ];
  }).copyWith(divider: '\n\n');

  final fieldClassesTemplate = u.ListPrinter(
    items: sharedFields,
    divider: '\n',
  ).map((field) => [printFieldSelectionSet(field, path)]);

  final fieldsTemplate = u.ListPrinter(items: selectionSet.fields);

  final sharedGetters = fieldsTemplate.copyWith(divider: '\n\n').map((field) {
    final type = printType(field.type, path: path + field.alias);
    return [
      u.docstring(field.schemaType.description),
      u.nullable(field.type),
      type.type,
      'get',
      u.dartName(field.alias),
      '=>',
      type.cast('value.${u.dartName(field.name)}')
    ];
  }).semicolons;

  final built = u.builtClass(
    path.className,
    implements: [ssClass],
    body: '''
      $sharedGetters

      $fragmentAliases

      $ssClass get value;
    ''',
  );

  return u.format('''
    ${inlineFragmentClasses}

    ${fieldClassesTemplate}

    ${u.docstring(description, '')}
    ${built}

  ''');
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
