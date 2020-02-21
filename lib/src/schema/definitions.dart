export './definitions/definitions.dart'
    hide
        NamedType,
        InterfaceTypeDefinition,
        ObjectTypeDefinition,
        UnionTypeDefinition,
        ListType,
        InputValueDefinition,
        FieldDefinition;

// we shadow many of the definitions with schema-aware equivalents
export './schema_aware.dart';
