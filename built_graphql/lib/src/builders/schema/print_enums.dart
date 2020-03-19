import 'package:built_graphql/src/builders/schema/print_type.dart';
import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/builders/utils.dart';

String printEnum(EnumTypeDefinition enumType) {
  if (!shouldGenerate(enumType.name)) {
    return '';
  }

  final name = className(enumType.name);
  final optionsTemplate = ListPrinter(items: enumType.values)
      .map((o) => ['static const $name ${o.name} = _\$${o.name}In${name}'])
      .semicolons;

  return format('''

  ${docstring(enumType.description, '')}
  class $name extends EnumClass {
    const $name._(String name) : super(name);

    ${optionsTemplate}

    static BuiltSet<$name> get values => _\$valuesFrom$name;
    static $name valueOf(String name) => _\$valueOf$name(name);

  static Serializer<$name> get serializer => ${serializerName(name)};
  }

  ''');
}
