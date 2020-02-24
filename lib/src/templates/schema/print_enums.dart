import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/templates/utils.dart';

String printEnum(EnumTypeDefinition enumType) {
  return format('''

  ${docstring(enumType.description, '')}
  enum ${className(enumType.name)} {
    ${enumType.values.map((v) => docstring(v.description) + v.name).join(', ')}
  }

  ''');
}
