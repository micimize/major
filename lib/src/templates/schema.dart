import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/templates/interface.dart';
import 'package:built_graphql/src/templates/object_type.dart';

String printSchema(GraphQLSchema schema) => '''

${schema.interaces.map(printInterface).join('\n')}

${schema.objectTypes.map(printObjectType).join('\n')}

''';
