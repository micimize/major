import 'package:built_graphql_generator/src/builders/executable/print_fragment.dart';
import 'package:built_graphql_generator/src/builders/executable/print_operation.dart';
import 'package:built_graphql_generator/src/executable/executable.dart';
import 'package:built_graphql_generator/src/builders/utils.dart';

String printExecutable(
  ExecutableDocument document,
  String serializersUniqueName,
  List<String> importedSerializers,
) {
  final rootPath = PathFocus.root();
  return format('''
  ${document.fragments.map((frag) => printFragment(frag, rootPath)).join('\n')}

  ${document.operations.map((op) => printOperation(op, rootPath)).join('\n')}

  const ${serializersUniqueName} = <Type>[
    ${importedSerializers.map((s) => '...$s').join(', ')},
    ${rootPath.manager.usedNames.where((name) => !name.contains('Builder')).join(',')},
  ];

  ${moduleSerializers(serializersUniqueName)}

  ${ignoreLints}
  ''');
}
