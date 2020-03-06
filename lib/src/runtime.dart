import 'package:meta/meta.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';

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

/*
/// unwrap a [Focus] into it's full [Fields] type from the schema.
///
/// The api is structured this way to allow for consuming projects
/// to optionally expose and extend the inner fields with custom logic,
/// while still allowing the generated types to name their internal field reference $fields
/// so as to avoid all possible field name collisions
Fields unfocus<Fields>(Focus<Fields> focus) => focus.$fields;
*/

@immutable
class ConvenienceSerializers {
  ConvenienceSerializers(Serializers serializers)
      : _serializers =
            (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();

  final Serializers _serializers;

  T Function(Map<String, Object> json) curryFromJson<T>(
    Serializer<T> serializer,
  ) =>
      (Map<String, Object> json) {
        try {
          return _serializers.deserializeWith(serializer, json);
        } catch (e) {
          print('oooh');
          throw e;
        }
      };

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
