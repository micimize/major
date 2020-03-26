import 'package:built_graphql/src/builders/config.dart' as config;
import 'package:meta/meta.dart';
import 'package:built_graphql/src/builders/utils.dart';

import '../../schema/definitions/definitions.dart' as d;

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
  if (typeConfig.scalars.containsKey(type.name)) {
    return TypeTemplate(typeConfig.scalars[type.name]);
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

TypeTemplate printType(
  d.GraphQLType type, {
  String prefix,
  PathFocus path,
}) {
  prefix ??= '';
  if (type is d.NamedType) {
    return _printPrimitive(type) ??
        _printEnum(type) ??
        TypeTemplate.of(
          resolveClassName(
            type.name,
            path: path,
            prefix: prefix,
          ),
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
  var builderName = resolveClassName(type.name, path: path, prefix: prefix);
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
      if (!nested)
        'toObjectBuilder()',
      if (!nested && type.type is d.InterfaceTypeDefinition)
        'build()'
    ].join('.');
  }
  if (type is d.ListType) {
    final innerType = printBuilderType(type.type);
    final innerSetter = printObjTypeSetter(type.type, 'i', true);

    return [
      'ListBuilder<$innerType>(',
      value,
      if (innerSetter != 'i') '.map<${innerType}>((i) => ${innerSetter})',
      ')',
    ].join('');
  }
  return value;
}

config.TypeConfig get typeConfig => config.configuration.forTypes;

String resolveClassName(String typeName, {PathFocus path, String prefix}) {
  prefix ??= '';
  final typeClassName = className(_replaceTypes(typeName));

  if (typeConfig.irreducibleTypes.containsKey(typeClassName)) {
    return prefix + typeClassName;
  }

  return path?.className ?? prefix + typeClassName;
}

String _replaceTypes(String typeName) {
  final replacement = typeConfig.replaceTypes[typeName] ?? typeName;
  if (replacement == typeName) {
    return typeName;
  }
  return _replaceTypes(replacement);
}

bool shouldGenerate(String typeName) =>
    typeConfig.irreducibleTypes[typeName]?.generate ?? true;
