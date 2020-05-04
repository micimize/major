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
  major_graphql: ^0.0.1
  # or major_graphql_flutter: ^0.0.1 for flutter

dev_dependencies:
  major_graphql_generator: ^0.0.1
  build_runner: ^1.7.4
```

