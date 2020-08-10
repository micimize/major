## 0.0.3

- `convenienceSerializersFunction` for injecting custom serializers
- (possibly broken) selection set helpers (`selectionSet`, `concretize`)
- improved `scalar`, `irreducibleTypes` and `replaceTypes` behavior
- custom json serialization plugin to address [empty map brittleness](https://github.com/google/built_value.dart/issues/902)
- fix #18 by adding nullable to mixins, fix #17 by using className mechanics


## 0.0.2

- **generator:** Refactored out models into [`gql/schema.dart` and `gql/operation.dart`](https://github.com/gql-dart/gql/tree/58c8bb9b70a008db56cafaf7da868785d98c7f9e/gql#gqlschemadart-and-gqloperationdart-experimental)


## 0.0.1

- Initial release
