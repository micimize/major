/*
import 'package:meta/meta.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';


abstract class FieldResults<Result>
    implements Built<FieldResults<Result>, FieldResultsBuilder<Result>> {
  // static Serializer<FieldResults> get serializer => _$fieldResultsSerializer;
  FieldResults._();

  @protected
  BuiltMap<BuiltMap<String, Object>, Result> get results;

  Result operator [](BuiltMap<String, Object> args) => results[args];

  factory FieldResults([void Function(FieldResultsBuilder) updates]) =
      _$FieldResults<Result>;


  static BuiltMap<String, Object> args({
    Episode episode,
  }) => {
        // only for optionals
        if (episode != null)
          'episode': episode,
      }

  Character call({
    Episode episode,
  }) =>
      results[args(
          episode: episode 
      )];
}

/// Custom builder classes must implement [Builder]. It must be abstract, and
/// have fields declared as normal public fields. Finally, it must have a
/// particular constructor and factory, as shown here.
abstract class FieldResultsBuilder<Result>
    implements Builder<FieldResults<Result>, FieldResultsBuilder<Result>> {
  @protected
  BuiltMap<BuiltMap<String, Object>, Result> results = {}.build();

  @nullable
  String aString;

  factory ValueWithDefaultsBuilder() = _$ValueWithDefaultsBuilder;
  ValueWithDefaultsBuilder._();
}


/// The query type, represents all of the entry points into our object graph
@immutable
class Query extends GraphQLObjectType with EquatableMixin {
  Query({
    this.hero,
    this.reviews,
    this.search,
    this.character,
    this.droid,
    this.human,
    this.starship,
  });

  final QueryHeroResults hero;

  final QueryReviewsResults reviews;

  final QuerySearchResults search;

  final QueryCharacterResults character;

  final QueryDroidResults droid;

  final QueryHumanResults human;

  final QueryStarshipResults starship;


  static final String schemaTypeName = "Query";
}







class QueryHeroResults extends FieldResults<QueryHeroArguments, Character> {
  const QueryHeroResults(Map<QueryHeroArguments, Character> results)
      : super(results);

  Character call({
    Episode episode,
  }) =>
      results[QueryHeroArguments(
        episode: episode,
      )];
}

abstract class GraphQLObjectType {
  /// Creates a new [GraphQLObjectType] with non-null values from [other] as attribute overrides
  GraphQLObjectType mergedLeftWith(covariant GraphQLObjectType other);

  /// Alias for [mergedLeftWith]
  GraphQLObjectType operator <<(covariant GraphQLObjectType other) =>
      mergedLeftWith(other);

  Set<String> get missingRequiredFields;

  void validate() {
    final missing = missingRequiredFields;
    assert(missing.isEmpty,
        "$runtimeType#$hashCode is missing required fields $missing");
  }

  bool get isValid => missingRequiredFields.isEmpty;
}

abstract class Partial<ObjectType extends GraphQLObjectType> extends Equatable {
  @protected
  const Partial.of(this.fields);

  final ObjectType fields;

  @override
  List<Object> get props => [fields];

  /// Creates a new [Partial<ObjectType>] with non-null values from [other] as attribute overrides
  Partial<ObjectType> mergedLeftWith(covariant Partial<ObjectType> other);
  //Partial<ObjectType> mergedLeftWith(covariant Partial<ObjectType> other);
  //    Partial.of(fields.mergedLeftWith(other.fields));

  /// Alias for [mergedLeftWith]
  Partial<ObjectType> operator <<(covariant Partial<ObjectType> other) =>
      mergedLeftWith(other);

  @protected
  Set<String> get missingRequiredFields => <String>{};

  void validate() {
    final missing = missingRequiredFields;
    assert(missing.isEmpty,
        "$runtimeType#$hashCode is missing required fields $missing");
  }

  bool get isValid => missingRequiredFields.isEmpty;
}

*/
