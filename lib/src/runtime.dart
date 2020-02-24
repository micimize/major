import 'package:meta/meta.dart';

/// We use SelectionSetFocus to subvert dart's type system to better suite the graphql structurally-oriented model
///
/// Use of the term focus is meant to reference functional lensing.
/// In essence, we hide all our fields and expose them piece-meal in the selection set,
/// which is essentially a composit lens of getters/setters
abstract class SelectionSetFocus<Fields> {
  @protected
  const SelectionSetFocus.of(this._fields);

  final Fields _fields;
}

/// unwrap a [SelectionSetFocus] into it's full [Fields] type from the schema.
///
/// The api is structured this way to allow for consuming projects
/// to optionally expose and extend the inner fields with custom logic,
/// while still allowing the generated types to name their internal field reference _fields
/// so as to avoid all possible field name collisions
Fields unfocus<Fields>(SelectionSetFocus<Fields> focus) => focus._fields;
