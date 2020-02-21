import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/templates/enums.dart';
import 'package:built_graphql/src/templates/interface.dart';
import 'package:built_graphql/src/templates/object_type.dart';
import 'package:built_graphql/src/templates/print_input_type.dart';
import 'package:built_graphql/src/templates/print_union.dart';
import 'package:built_graphql/src/templates/utils.dart';

String printSchema(GraphQLSchema schema) {
  return format('''
  ${schema.enums.map(printEnum).join('\n')}

  ${schema.interaces.map(printInterface).join('\n')}

  ${schema.objectTypes.map(printObjectType).join('\n')}

  ${schema.unions.map(printUnion).join('\n')}

  ${schema.inputObjectTypes.map(printInputObjectType).join('\n')}

  ''');
}
