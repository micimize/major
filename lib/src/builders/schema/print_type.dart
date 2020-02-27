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

String printType(d.GraphQLType type, {String prefix = ''}) {
  if (type is d.NamedType) {
    return defaultPrimitives[type.name] ?? prefix + className(type.name);
  }
  if (type is d.ListType) {
    return 'BuiltList<${printType(type.type)}>';
  }

  throw ArgumentError('$type is unsupported');
}
