import 'package:meta/meta.dart';
import 'package:built_graphql/src/builders/utils.dart';

import '../../schema/definitions/definitions.dart' as d;

final defaultPrimitives = {
  'String': 'String',
  'Int': 'int',
  'Float': 'double',
  'Boolean': 'bool',
  'ID': 'String',
  'int': 'int',
  'bool': 'bool',
  'double': 'double',
  'num': 'num',
  'dynamic': 'dynamic',
  'Object': 'Object',
  'DateTime': 'DateTime',
  'Date': 'DateTime'
};

String identity(String i) => i;

String Function(String value) _of(String type) => (value) => '$type.of($value)';

@immutable
class TypeTemplate {
  TypeTemplate(this.type, [this.cast = identity]);
  TypeTemplate.of(this.type) : cast = _of(type);
  final String type;
  final String Function(String value) cast;

  @override
  String toString() => type;
}

TypeTemplate printType(d.GraphQLType type, {String prefix, PathFocus path}) {
  prefix ??= '';
  if (type is d.NamedType) {
    if (defaultPrimitives.containsKey(type.name)) {
      return TypeTemplate(defaultPrimitives[type.name]);
    }
    if (type.hasResolver && type.type is d.EnumTypeDefinition) {
      return TypeTemplate(type.name);
    }

    return TypeTemplate.of(path?.className ?? prefix + className(type.name));
  }
  if (type is d.ListType) {
    final innerTemplate = printType(type.type, prefix: prefix, path: path);
    final innerCast = innerTemplate.cast('i');
    return TypeTemplate(
      'BuiltList<${innerTemplate.type}>',
      innerTemplate.cast == identity
          ? identity
          : (inner) => 'BuiltList($inner.map((i) => ${innerCast}))',
    );
  }

  throw ArgumentError('$type is unsupported');
}
