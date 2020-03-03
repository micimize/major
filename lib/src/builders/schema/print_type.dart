import 'package:built_graphql/src/builders/config.dart' as config;
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

TypeTemplate _printPrimitive(d.NamedType type) {
  if (defaultPrimitives.containsKey(type.name)) {
    return TypeTemplate(defaultPrimitives[type.name]);
  }
  return null;
}

TypeTemplate _printEnum(d.NamedType type) {
  if (type.hasResolver && type.type is d.EnumTypeDefinition) {
    return TypeTemplate(type.name);
  }
  return null;
}

TypeTemplate _printList(
  d.ListType type,
  String listType,
  TypeTemplate Function(d.GraphQLType type) innerCallback,
) {
  final innerTemplate = innerCallback(type.type);
  final innerCast = innerTemplate.cast('i');
  return TypeTemplate(
    '$listType<${innerTemplate.type}>',
    innerTemplate.cast == identity
        ? identity
        : (inner) =>
            '$listType($inner.map<${innerTemplate.type}>((i) => ${innerCast}))',
  );
}

TypeTemplate printType(d.GraphQLType type, {String prefix, PathFocus path}) {
  prefix ??= '';
  if (type is d.NamedType) {
    return _printPrimitive(type) ??
        _printEnum(type) ??
        TypeTemplate.of(
          path?.className ?? prefix + className(type.name),
        );
  }
  if (type is d.ListType) {
    return _printList(
      type,
      'BuiltList',
      (type) => printType(type, prefix: prefix, path: path),
    );
  }

  throw ArgumentError('$type is unsupported');
}

TypeTemplate printBuilderType(d.GraphQLType type,
    {String prefix, PathFocus path}) {
  prefix ??= '';
  if (type is d.NamedType) {
    return _printPrimitive(type) ??
        _printEnum(type) ??
        _printNestedBuilder(type, prefix: prefix, path: path);
  }
  if (type is d.ListType) {
    return _printList(
      type,
      config.nestedBuilders ? 'ListBuilder' : 'BuiltList',
      (type) => printBuilderType(type, prefix: prefix, path: path),
    );
  }

  throw ArgumentError('$type is unsupported');
}

TypeTemplate _printNestedBuilder(d.NamedType type,
    {String prefix, PathFocus path}) {
  var builderName = (path?.className ?? prefix + className(type.name));
  if (config.nestedBuilders) {
    builderName += 'Builder';

    return TypeTemplate(
      builderName,
      (String value) => '$builderName()..\$fields = $value',
    );
  } else {
    return TypeTemplate.of(builderName);
  }
}

String printObjTypeSetter(d.GraphQLType type,
    [String value = 'value', bool nested = false]) {
  if (type is d.NamedType &&
      type.hasResolver &&
      type.type is d.TypeDefinitionWithFieldSet) {
    return [
      value,
      // config.protectedFields,
      if (!nested && type.type is d.InterfaceTypeDefinition)
        'toObjectBuilder().build()',
    ].join('.');
  }
  if (type is d.ListType) {
    final innerType = printBuilderType(type.type);
    final innerSetter = printObjTypeSetter(type.type, 'i');

    return [
      'ListBuilder<$innerType>(',
      value,
      if (innerSetter != 'i') '.map<${innerType}>((i) => ${innerSetter})',
      ')',
    ].join('');
  }
  return value;
}
