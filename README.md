# `built_graphql`

`built_graphql` uses the dart `build` system and `gql` to generate `built_value` classes, primarily for use in client side applications.

### Packages
* [`built_graphql`](https://pub.dev/packages/built_graphql)
* [`built_graphql_generator`](https://pub.dev/packages/built_graphql_generator)
* [`built_graphql_flutter`](https://pub.dev/packages/built_graphql_flutter)


## Usage

### `build.yaml`:

```yaml
targets:
  $default:
    builders:
      built_graphql_generator|builder:
        enabled: true
        options:
          schema: built_graphql_example|lib/graphql/schema.graphql
```

### `pubspec.yaml`:

```yaml
dependencies:
  built_graphql: ^0.0.1
  # or built_graphql_flutter: ^0.0.1 for flutter

dev_dependencies:
  built_graphql_generator: ^0.0.1
  build_runner: ^1.7.4
```
