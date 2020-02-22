import 'package:meta/meta.dart';

abstract class Partial<Parent> {
  @protected
  const Partial.of(this.fields);

  @protected
  final Parent fields;

  /*
  /// Creates a new [Partial<Parent>] with non-null values from [other] as attribute overrides
  Partial<Parent> mergedLeftWith(
      covariant Partial<Parent> other);
  //Partial<Parent> mergedLeftWith(covariant Partial<Parent> other);
  //    Partial.of(fields.mergedLeftWith(other.fields));

  /// Alias for [mergedLeftWith]
  Partial<Parent> operator <<(
          covariant Partial<Parent> other) =>
      mergedLeftWith(other);
  */

  @protected
  Set<String> get missingRequiredFields => <String>{};

  void validate() {
    final missing = missingRequiredFields;
    assert(missing.isEmpty,
        "$runtimeType#$hashCode is missing required fields $missing");
  }

  bool get isValid => missingRequiredFields.isEmpty;
}
