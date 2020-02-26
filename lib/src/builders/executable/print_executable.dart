import 'package:built_graphql/src/builders/executable/print_fragment.dart';
import 'package:built_graphql/src/builders/executable/print_operation.dart';
import 'package:built_graphql/src/executable/executable.dart';
import 'package:built_graphql/src/builders/utils.dart';

String printExecutable(ExecutableDocument document) {
  return format('''
  ${document.fragments.map(printFragment).join('\n')}

  ${document.operations.map(printOperation).join('\n')}
  ''');
}
