export './definitions/definitions.dart'
    hide
        NamedType,
        InterfaceTypeDefinition,
        ObjectTypeDefinition,
        UnionTypeDefinition,
        ListType,
        InputValueDefinition,
        FieldDefinition,
        // while it is defined in value_types.dart so that Value.fromNode can be made complete,
        // Variables are not part of the schema definition language
        Variable;

// we shadow many of the definitions with schema-aware equivalents
export './schema_aware.dart';
