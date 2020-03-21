# `built_graphql`

`built_graphql` uses the dart `build` system and `gql` to generate `built_value` classes, currently primarily for use in client side applications.

## Usage

### `build.yaml`:

```yaml
targets:
  $default:
    builders:
      built_graphql|builder:
        enabled: true
        options:
          schema: built_graphql_example|lib/graphql/schema.graphql
```

### `pubspec.yaml`:

```yaml
dependencies:
  built_graphql: # TODO publish
  built_value_generator: ^7.0.9 #TODO depends on my PR
  built_collection: ^4.3.2
  built_value: ^7.0.9

dev_dependencies:
  build_runner: ^1.7.4
```
