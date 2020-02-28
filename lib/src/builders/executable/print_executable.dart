import 'package:built_graphql/src/builders/executable/print_fragment.dart';
import 'package:built_graphql/src/builders/executable/print_operation.dart';
import 'package:built_graphql/src/executable/executable.dart';
import 'package:built_graphql/src/builders/utils.dart';

String printExecutable(ExecutableDocument document) {
  final rootPath = PathFocus.root();
  return format('''
  ${document.fragments.map((frag) => printFragment(frag, rootPath)).join('\n')}

  ${document.operations.map((op) => printOperation(op, rootPath)).join('\n')}
  ''');
}
