import 'package:built_collection/built_collection.dart';
import 'package:major_graphql/src/json_plugin.dart';
import 'package:meta/meta.dart';
import 'package:built_value/serializer.dart';

abstract class BuiltToJson {
  Map<String, Object> toJson();
}

//import 'package:meta/meta.dart';

/// We use SelectionSetFocus to subvert dart's type system to better suite the graphql structurally-oriented model
///
/// Use of the term focus is meant to reference functional lensing.
/// In essence, we hide all our fields and expose them piece-meal in the selection set,
/// which is essentially a composit lens of getters/setters
abstract class SelectionSet<Fields, FieldsBuilder> {
  FieldsBuilder toObjectBuilder();
}

@immutable
class ConvenienceSerializers {
  ConvenienceSerializers(Serializers serializers)
      : _serializers = (serializers.toBuilder()
              ..add(AutoUtcIso8601DateTimeSerializer())
              ..addPlugin(MajorGraphQLJsonPlugin()))
            .build();

  final Serializers _serializers;

  T Function(Map<String, Object> json) curryFromJson<T>(
    Serializer<T> serializer,
  ) =>
      (Map<String, Object> json) {
        try {
          return _serializers.deserializeWith(serializer, json);
        } catch (e) {
          print('Failed to deserialize $json');
          rethrow;
        }
      };

  // TODO adding __typename in toJson() makes it incongruous with built value serialzers
  Map<String, Object> Function(T instance) curryToJson<T>(
    Serializer<T> serializer,
  ) =>
      (T instance) => _serializers.serializeWith(serializer, instance)
          as Map<String, Object>;
}

class InterfaceSerializer<I extends BuiltToJson>
    implements StructuredSerializer<I> {
  const InterfaceSerializer({@required this.typeMap, String wireName})
      : _wireName = wireName;

  final Map<String, Type> typeMap;

  @override
  Iterable<Type> get types => [I, ...typeMap.values];

  final String _wireName;

  @override
  String get wireName => _wireName ?? '$I';

  StructuredSerializer<I> _serializerForType(
    Serializers serializers,
    Type type,
  ) =>
      serializers.serializerForType(type) as StructuredSerializer<I>;

  @override
  Iterable<Object> serialize(
    Serializers serializers,
    I object, {
    FullType specifiedType = FullType.unspecified,
  }) =>
      _serializerForType(serializers, object.runtimeType).serialize(
        serializers,
        object,
        specifiedType: specifiedType,
      );

  @override
  I deserialize(
    Serializers serializers,
    Iterable<Object> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final _serialized = serialized.toList();
    final type = typeMap[_getTypeName(_serialized)];
    final concreteSerializer = _serializerForType(serializers, type);
    return concreteSerializer.deserialize(
      serializers,
      _serialized,
      specifiedType: specifiedType,
    );
  }
}

String _getTypeName(Iterable<Object> serialized) {
  final iterator = serialized.iterator;
  while (iterator.moveNext()) {
    final key = iterator.current as String;
    iterator.moveNext();
    final dynamic value = iterator.current;
    if (key == '__typename') {
      return value as String;
    }
  }
  throw ArgumentError('$serialized contains no __typename');
}

class AutoUtcIso8601DateTimeSerializer
    implements PrimitiveSerializer<DateTime> {
  final bool structured = false;
  @override
  final Iterable<Type> types = BuiltList(<Type>[DateTime]);
  @override
  final String wireName = 'DateTime';

  @override
  Object serialize(Serializers serializers, DateTime dateTime,
      {FullType specifiedType = FullType.unspecified}) {
    return dateTime.toUtc().toIso8601String();
  }

  @override
  DateTime deserialize(Serializers serializers, Object serialized,
      {FullType specifiedType = FullType.unspecified}) {
    return DateTime.parse(serialized as String).toUtc();
  }
}
