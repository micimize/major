import 'package:built_graphql/src/builders/executable/print_selection_set.dart';
import 'package:meta/meta.dart';
import 'package:built_graphql/src/executable/definitions.dart';
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
  final focusClass = '${u.bgPrefix}.Focus<$schemaClass>';

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
    final _path = path + 'on' + fragment.onTypeName;
    return [
      _path.className,
      'get on${fragment.onTypeName} =>'
          '\$fields is ${fragment.onTypeName} ?',
      '${_path.className}.of(\$fields as ${fragment.onTypeName}) : null'
    ];
  }).semicolons;

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
      type.cast('\$fields?.${u.dartName(field.name)}')
    ];
  }).semicolons;

  final built = u.builtClass(
    path.className,
    implements: [focusClass],
    body: '''
      factory ${path.className}.from(${focusClass} focus) => _\$${path.className}._(\$fields: focus.\$fields);
      factory ${path.className}.of($schemaClass objectType) => _\$${path.className}._(\$fields: objectType);

      $sharedGetters

      $fragmentAliases

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
