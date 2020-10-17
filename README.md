# `major_graphql`

`major_graphql` uses the dart `build` system and `gql` to generate `built_value` classes, primarily for use in client side applications.

### Packages

- [`major_graphql`](https://pub.dev/packages/major_graphql)
- [`major_graphql_generator`](https://pub.dev/packages/major_graphql_generator)
- [`major_graphql_flutter`](https://pub.dev/packages/major_graphql_flutter)

There is also an example [`major_todo_app`](https://github.com/micimize/major_todo_app) which is livecoded on [youtube](https://www.youtube.com/channel/UCj39MVr1fuFtE1eDNXDGJuQ).

## Usage

### `build.yaml`:

```yaml
targets:
  $default:
    builders:
      major_graphql_generator|builder:
        enabled: true
        options:
          schema: major_graphql_example|lib/graphql/schema.graphql
```

### `pubspec.yaml`:

```yaml
dependencies:
  major_graphql: ^0.0.3
  # or major_graphql_flutter: ^0.0.1 for flutter

dev_dependencies:
  major_graphql_generator: ^0.0.3
  build_runner: ^1.7.4
```


### dev notes
* These libraries are **highly experimental**, and the generator is currently **quite slow**.
* [custom scalar usage & configuration](https://github.com/micimize/major/issues/21#issuecomment-671395549) 
* [unions appear to be broken](https://github.com/micimize/major/issues/22)
* There are currently numerous smaller [limitations and caveats](https://github.com/micimize/major/issues/23)
* `irreducibleTypes` are types for which selection sets should not be generated. You can supply your own type for them as well by setting `generate: false`. They are still assumed to be built value types unless they are in the `scalars` map. Not that you need to refer to them in the config by their graphql type name.
* `replaceTypes` renames all references to a given type
* `mixins` can be added conditionally:
```yaml
mixins:
  - name: Entity
    when:
      fields:
      - entityId
      - validFrom
      - validUntil
      # disable mixin for these classes
      nameNot:
        - MySpecialEntity
        - MyOtherSpecialEntity
```
* userland code can be injected via `imports` and `exports` (and needs to be to use scalars and mixins):
```yaml
schema:
  path: savvy_app|lib/graphql/schema.graphql
  imports:
    - package:savvy_app/graphql/base.dart
    - package:built_value/json_object.dart
  exports:
    - package:savvy_app/graphql/base.dart
    - package:built_value/json_object.dart
```

