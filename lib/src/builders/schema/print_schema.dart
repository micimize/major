import 'package:built_graphql/src/schema/schema.dart';
import 'package:built_graphql/src/builders/schema/print_enums.dart';
import 'package:built_graphql/src/builders/schema/print_interface.dart';
import 'package:built_graphql/src/builders/schema/print_object_type.dart';
import 'package:built_graphql/src/builders/schema/print_input_type.dart';
import 'package:built_graphql/src/builders/schema/print_union.dart';
import 'package:built_graphql/src/builders/utils.dart';

String printSchema(GraphQLSchema schema) {
  return format('''
  /*
   * Enums
   */
  ${schema.enums.map(printEnum).join('\n')}

  /*
   * Interfaces
   */
  ${schema.interaces.map(printInterface).join('\n')}

  /*
   * Object Types
   */
  ${schema.objectTypes.map(printObjectType).join('\n')}

  /*
   * Unions
   */
  ${schema.unions.map(printUnion).join('\n')}

  /*
   * Inputs
   */
  ${schema.inputObjectTypes.map(printInputObjectType).join('\n')}

  ''');
}
