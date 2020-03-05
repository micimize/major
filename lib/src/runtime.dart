import 'package:meta/meta.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';

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
      (Map<String, Object> json) =>
          _serializers.deserializeWith(serializer, json);

  Map<String, Object> Function(T instance) curryToJson<T>(
    Serializer<T> serializer,
  ) =>
      (T instance) => _serializers.serializeWith(serializer, instance)
          as Map<String, Object>;
}
